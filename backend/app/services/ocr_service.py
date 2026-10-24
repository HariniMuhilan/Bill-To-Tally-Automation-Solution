"""OCR Service Adapter for Photo Invoice Processing.

Extracts text, bounding boxes, and confidence scores from photo images (JPG, PNG, WEBP, etc.)
using PaddleOCR with an adaptable interface per AGENTS.md Section 3.
"""

from abc import ABC, abstractmethod
import io
import logging
from pathlib import Path
from typing import List, Optional, Union
import sys
import numpy as np
from PIL import Image, ImageOps

# Ensure project root and backend directory are in sys.path for direct execution or IDE tools
_current_dir = Path(__file__).resolve().parent
_project_root = _current_dir.parent.parent.parent
if str(_project_root) not in sys.path:
    sys.path.insert(0, str(_project_root))
_backend_dir = _project_root / "backend"
if str(_backend_dir) not in sys.path:
    sys.path.insert(0, str(_backend_dir))

try:
    from backend.app.core.config import settings
    from backend.app.schemas.invoice import OCRLine, OCRResult
except (ImportError, ValueError):
    try:
        from app.core.config import settings
        from app.schemas.invoice import OCRLine, OCRResult
    except (ImportError, ValueError):
        from ..core.config import settings
        from ..schemas.invoice import OCRLine, OCRResult

logger = logging.getLogger(__name__)


def load_image_as_numpy(
    image_input: Union[str, Path, bytes, io.BytesIO, Image.Image]
) -> np.ndarray:
    """Load image from path, bytes, or PIL Image, normalize EXIF orientation, and return RGB NumPy array."""
    if isinstance(image_input, (str, Path)):
        img = Image.open(str(image_input))
    elif isinstance(image_input, bytes):
        img = Image.open(io.BytesIO(image_input))
    elif isinstance(image_input, io.BytesIO):
        img = Image.open(image_input)
    elif isinstance(image_input, Image.Image):
        img = image_input
    else:
        raise ValueError(f"Unsupported image input type: {type(image_input)}")

    # Automatically rotate phone camera photos based on EXIF orientation tag
    img = ImageOps.exif_transpose(img)

    # Ensure 3-channel RGB (handles RGBA, grayscale, or palette images)
    if img.mode != "RGB":
        img = img.convert("RGB")

    return np.array(img)


class BaseOCRAdapter(ABC):
    """Abstract Base Class for OCR adapters."""

    @abstractmethod
    def extract_from_image(
        self, image_input: Union[str, Path, bytes, io.BytesIO, Image.Image]
    ) -> OCRResult:
        """Extract text and metadata from a bill/invoice photo."""
        raise NotImplementedError


class PaddleOCRAdapter(BaseOCRAdapter):
    """PaddleOCR adapter optimized for invoice/receipt photos."""

    _instance: Optional["PaddleOCRAdapter"] = None
    _engine = None

    def __new__(cls, *args, **kwargs):
        """Singleton pattern so models are loaded only once in memory."""
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    def _get_engine(self):
        """Lazy loader for PaddleOCR engine."""
        if self._engine is None:
            logger.info("Initializing PaddleOCR engine with lang=%s", settings.OCR_LANG)
            from paddleocr import PaddleOCR
            # use_angle_cls=True auto-corrects 90/180/270 rotated bill images
            self._engine = PaddleOCR(
                use_angle_cls=True,
                lang=settings.OCR_LANG,
                show_log=False,
            )
        return self._engine

    def extract_from_image(
        self, image_input: Union[str, Path, bytes, io.BytesIO, Image.Image]
    ) -> OCRResult:
        """Extract text lines, bounding boxes, and confidence scores from an image."""
        img_np = load_image_as_numpy(image_input)
        engine = self._get_engine()

        # Run PaddleOCR inference
        raw_results = engine.ocr(img_np, cls=True)

        ocr_lines: List[OCRLine] = []

        if not raw_results or not raw_results[0]:
            # Empty detection (e.g., blank or corrupted image)
            return OCRResult(
                raw_text="",
                lines=[],
                page_count=1,
                average_confidence=0.0,
            )

        # PaddleOCR returns [[ [box_coords, (text, score)], ... ]]
        page_results = raw_results[0]
        for item in page_results:
            if not item or len(item) < 2:
                continue

            box = item[0]
            text_tuple = item[1]
            text = str(text_tuple[0]).strip()
            score = float(text_tuple[1])

            # Bound score to [0.0, 1.0]
            confidence = max(0.0, min(1.0, score))

            if text:
                ocr_lines.append(
                    OCRLine(
                        text=text,
                        confidence=confidence,
                        bbox=box,
                    )
                )

        if not ocr_lines:
            return OCRResult(
                raw_text="",
                lines=[],
                page_count=1,
                average_confidence=0.0,
            )

        # Sort lines naturally (top-to-bottom, left-to-right) by top-left y-coordinate
        # box[0] is [top_left_x, top_left_y]
        ocr_lines.sort(key=lambda line: (line.bbox[0][1] if line.bbox else 0))

        raw_text = "\n".join(line.text for line in ocr_lines)
        avg_conf = sum(line.confidence for line in ocr_lines) / len(ocr_lines)

        return OCRResult(
            raw_text=raw_text,
            lines=ocr_lines,
            page_count=1,
            average_confidence=round(avg_conf, 4),
        )


class MockOCRAdapter(BaseOCRAdapter):
    """Deterministic Mock OCR Adapter for offline and fast unit tests."""

    def __init__(self, mock_result: Optional[OCRResult] = None):
        self.mock_result = mock_result

    def extract_from_image(
        self, image_input: Union[str, Path, bytes, io.BytesIO, Image.Image]
    ) -> OCRResult:
        if self.mock_result:
            return self.mock_result

        # Default synthetic invoice lines for testing
        lines = [
            OCRLine(text="TAX INVOICE", confidence=0.99, bbox=[[10, 10], [100, 10], [100, 25], [10, 25]]),
            OCRLine(text="Invoice No: INV-2026-001", confidence=0.98, bbox=[[10, 30], [180, 30], [180, 45], [10, 45]]),
            OCRLine(text="Date: 2026-10-24", confidence=0.97, bbox=[[10, 50], [120, 50], [120, 65], [10, 65]]),
            OCRLine(text="Supplier: Apex Hardware Supplies", confidence=0.96, bbox=[[10, 70], [220, 70], [220, 85], [10, 85]]),
            OCRLine(text="GSTIN: 33AAAAA0000A1Z5", confidence=0.99, bbox=[[10, 90], [190, 90], [190, 105], [10, 105]]),
            OCRLine(text="Item: Steel Hex Bolts M10x50", confidence=0.95, bbox=[[10, 110], [210, 110], [210, 125], [10, 125]]),
            OCRLine(text="Qty: 50 Price: 20.00 Amount: 1000.00", confidence=0.96, bbox=[[10, 130], [250, 130], [250, 145], [10, 145]]),
            OCRLine(text="CGST 9%: 90.00 SGST 9%: 90.00", confidence=0.97, bbox=[[10, 150], [230, 150], [230, 165], [10, 165]]),
            OCRLine(text="Total Amount: 1180.00", confidence=0.99, bbox=[[10, 170], [180, 170], [180, 185], [10, 185]]),
        ]
        raw_text = "\n".join(l.text for l in lines)
        avg_conf = sum(l.confidence for l in lines) / len(lines)
        return OCRResult(
            raw_text=raw_text,
            lines=lines,
            page_count=1,
            average_confidence=round(avg_conf, 4),
        )


def get_ocr_service(engine: Optional[str] = None) -> BaseOCRAdapter:
    """Factory function returning the configured OCR engine adapter."""
    chosen_engine = engine or settings.OCR_ENGINE
    if chosen_engine == "mock":
        return MockOCRAdapter()
    return PaddleOCRAdapter()
