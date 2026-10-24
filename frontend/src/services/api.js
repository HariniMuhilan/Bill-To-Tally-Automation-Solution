/**
 * Bill-to-Tally Backend API Client
 * Connects to FastAPI backend at /api endpoints (proxied to http://127.0.0.1:8000).
 */

const API_BASE = '';

export async function getSystemHealth() {
  try {
    const res = await fetch(`${API_BASE}/api/health`, {
      headers: { 'Accept': 'application/json' },
    });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return await res.json();
  } catch (err) {
    return {
      status: 'offline',
      error: err.message,
      app_env: 'development',
      ocr_engine: 'paddleocr',
      posting_enabled: false,
    };
  }
}

export async function getTallyHealth() {
  try {
    const res = await fetch(`${API_BASE}/api/tally/health`, {
      headers: { 'Accept': 'application/json' },
    });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return await res.json();
  } catch (err) {
    return {
      tally_host: '127.0.0.1',
      tally_port: 9000,
      posting_enabled: false,
      connected: false,
      company: 'ASHAN TEST LABS PVT LTD',
    };
  }
}

/**
 * Uploads an invoice document (JPG/PNG/PDF/WEBP) to FastAPI backend OCR extraction endpoint.
 * Backend route: POST /api/invoices/ocr
 */
export async function uploadInvoiceFile(file) {
  const formData = new FormData();
  formData.append('file', file);

  try {
    const res = await fetch(`${API_BASE}/api/invoices/ocr`, {
      method: 'POST',
      body: formData,
    });

    if (!res.ok) {
      const errData = await res.json().catch(() => ({}));
      throw new Error(errData.detail || `Server returned HTTP ${res.status}`);
    }

    const data = await res.json();
    return {
      success: true,
      data,
    };
  } catch (err) {
    console.warn('Backend OCR call failed or backend offline. Using client fallback:', err);
    return {
      success: false,
      error: err.message,
    };
  }
}

/**
 * Direct Gemini extraction from raw OCR result.
 * Backend route: POST /api/invoices/extract-text
 */
export async function extractFromRawOcr(ocrResult) {
  try {
    const res = await fetch(`${API_BASE}/api/invoices/extract-text`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(ocrResult),
    });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return await res.json();
  } catch (err) {
    console.error('Extract from raw OCR failed:', err);
    throw err;
  }
}

export function getInvoiceFileUrl(filename) {
  if (!filename) return '';
  return `${API_BASE}/api/invoices/file/${encodeURIComponent(filename)}`;
}
