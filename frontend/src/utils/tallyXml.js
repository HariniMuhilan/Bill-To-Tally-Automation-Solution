/**
 * TallyPrime Purchase Voucher XML Generator
 * Follows Tally DTD and AGENTS.md Section 4 rules.
 */

export function generateTallyPurchaseXml(inv) {
  if (!inv) return '';
  const dateStr = inv.tallyDate || (inv.invoiceDate ? inv.invoiceDate.replace(/-/g, '') : '20261018');
  const supplier = inv.supplierMapped || inv.supplierRaw || 'Supplier Ledger';
  const grandTotal = Number(inv.grandTotal || 0).toFixed(2);
  const cgst = Number(inv.cgst || 0).toFixed(2);
  const sgst = Number(inv.sgst || 0).toFixed(2);

  const linesXml = (inv.lines || []).map(line => {
    const rate = Number(line.rate || 0).toFixed(2);
    const taxable = Number(line.taxable || 0).toFixed(2);
    const unit = line.unit || 'NOS';
    const stockItem = line.stockItem || 'Default Stock Item';

    return `            <ALLINVENTORYENTRIES.LIST>
              <STOCKITEMNAME>${stockItem}</STOCKITEMNAME>
              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>
              <RATE>${rate} / ${unit}</RATE>
              <ACTUALQTY>${line.qty} ${unit}</ACTUALQTY>
              <BILLEDQTY>${line.qty} ${unit}</BILLEDQTY>
              <AMOUNT>-${taxable}</AMOUNT>
              <ACCOUNTINGALLOCATIONS.LIST>
                <LEDGERNAME>Purchase - GST 18%</LEDGERNAME>
                <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>
                <AMOUNT>-${taxable}</AMOUNT>
              </ACCOUNTINGALLOCATIONS.LIST>
            </ALLINVENTORYENTRIES.LIST>`;
  }).join('\n');

  return `<ENVELOPE>
  <HEADER>
    <TALLYREQUEST>Import Data</TALLYREQUEST>
  </HEADER>
  <BODY>
    <IMPORTDATA>
      <REQUESTDESC>
        <REPORTNAME>Vouchers</REPORTNAME>
        <STATICVARIABLES>
          <SVCURRENTCOMPANY>ASHAN TEST LABS PVT LTD</SVCURRENTCOMPANY>
        </STATICVARIABLES>
      </REQUESTDESC>
      <REQUESTDATA>
        <TALLYMESSAGE xmlns:UDF="TallyUDF">
          <VOUCHER VCHTYPE="Purchase" ACTION="Create" OBJVIEW="Invoice Voucher View">
            <DATE>${dateStr}</DATE>
            <VOUCHERTYPENAME>Purchase</VOUCHERTYPENAME>
            <REFERENCE>${inv.invoiceNo || 'REF-001'}</REFERENCE>
            <REFERENCEDATE>${dateStr}</REFERENCEDATE>
            <PARTYLEDGERNAME>${supplier}</PARTYLEDGERNAME>
            <PERSISTEDVIEW>Invoice Voucher View</PERSISTEDVIEW>
            <NARRATION>Purchase Invoice ${inv.invoiceNo} auto-generated via Bill-to-Tally Automation</NARRATION>
            
            <!-- Supplier Ledger Credit Entry -->
            <ALLLEDGERENTRIES.LIST>
              <LEDGERNAME>${supplier}</LEDGERNAME>
              <ISDEEMEDPOSITIVE>No</ISDEEMEDPOSITIVE>
              <AMOUNT>${grandTotal}</AMOUNT>
            </ALLLEDGERENTRIES.LIST>

            <!-- Line Items Inventory Allocations -->
${linesXml}

            <!-- Tax Ledgers -->
            <ALLLEDGERENTRIES.LIST>
              <LEDGERNAME>Input CGST @ 9%</LEDGERNAME>
              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>
              <AMOUNT>-${cgst}</AMOUNT>
            </ALLLEDGERENTRIES.LIST>
            <ALLLEDGERENTRIES.LIST>
              <LEDGERNAME>Input SGST @ 9%</LEDGERNAME>
              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>
              <AMOUNT>-${sgst}</AMOUNT>
            </ALLLEDGERENTRIES.LIST>
          </VOUCHER>
        </TALLYMESSAGE>
      </REQUESTDATA>
    </IMPORTDATA>
  </BODY>
</ENVELOPE>`;
}
