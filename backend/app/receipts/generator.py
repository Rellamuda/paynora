import hashlib
from datetime import datetime, timezone
from typing import Dict, Any

class ReceiptGenerator:
    """
    Generates official, tamper-evident PayNora transaction alert receipts.
    Supports structured JSON data and print-ready styled HTML receipts.
    """

    @classmethod
    def generate_receipt_data(cls, transfer: Dict[str, Any]) -> Dict[str, Any]:
        """Generate structured financial receipt payload with cryptographic security seal."""
        transfer_id = transfer.get("transfer_id", "trf_unknown")
        created_at = transfer.get("created_at", datetime.now(timezone.utc).isoformat())
        source_currency = transfer.get("source_currency", "USD")
        source_amount = transfer.get("source_amount", "0.00")
        destination_currency = transfer.get("destination_currency") or transfer.get("selected_recipient_currency") or source_currency
        recipient_name = transfer.get("recipient_name", "Valued Customer")
        fee = transfer.get("estimated_fee", "0.00")
        gateway = transfer.get("payout_gateway", "Smart Dual Gateway (Flutterwave / Paystack)")
        status = transfer.get("state", "COMPLETED")

        receipt_number = f"REC-PN-{transfer_id.replace('trf_', '').upper()}"

        # Calculate tamper-evident cryptographic hash
        seal_string = f"{receipt_number}:{transfer_id}:{source_amount}:{source_currency}:{recipient_name}:{created_at}"
        security_seal = hashlib.sha256(seal_string.encode()).hexdigest()

        return {
            "receipt_number": receipt_number,
            "transaction_reference": transfer_id,
            "timestamp": created_at,
            "status": status,
            "issuer": {
                "name": "PayNora Global Inc.",
                "support_email": "support@paynora.com",
                "regulated_status": "Licensed Global Money Movement Platform"
            },
            "sender": {
                "user_id": transfer.get("user_id", "usr_demo"),
                "source_country": transfer.get("source_country", "GLOBAL")
            },
            "recipient": {
                "name": recipient_name,
                "destination_country": transfer.get("destination_country", "GLOBAL"),
                "destination_currency": destination_currency,
                "payout_method": transfer.get("payout_method", "Instant Bank Transfer")
            },
            "financials": {
                "send_amount": source_amount,
                "source_currency": source_currency,
                "transfer_fee": fee,
                "total_charged": f"{float(source_amount) + float(fee):.2f}",
                "destination_currency": destination_currency,
                "gateway_routing": gateway
            },
            "security_seal": security_seal
        }

    @classmethod
    def generate_html_receipt(cls, receipt_data: Dict[str, Any]) -> str:
        """Render print-ready HTML receipt with PayNora branding and printable CSS."""
        r = receipt_data
        fin = r["financials"]
        status_color = "#10B981" if r["status"] in ["COMPLETED", "SUCCESSFUL"] else "#F59E0B"

        html = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>PayNora Transaction Receipt - {r['receipt_number']}</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body {{
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      background-color: #F8FAFC;
      color: #0F172A;
      margin: 0;
      padding: 24px;
      display: flex;
      justify-content: center;
    }}
    .receipt-card {{
      background: #FFFFFF;
      max-width: 520px;
      width: 100%;
      border-radius: 16px;
      box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.05), 0 8px 10px -6px rgba(0, 0, 0, 0.03);
      border: 1px solid #E2E8F0;
      overflow: hidden;
    }}
    .header {{
      background: linear-gradient(135deg, #0A1128 0%, #001F54 100%);
      color: #FFFFFF;
      padding: 32px 24px;
      text-align: center;
    }}
    .header h1 {{
      margin: 0;
      font-size: 24px;
      letter-spacing: -0.5px;
      font-weight: 700;
    }}
    .header p {{
      margin: 6px 0 0 0;
      font-size: 13px;
      color: #94A3B8;
    }}
    .status-badge {{
      display: inline-block;
      margin-top: 14px;
      background: {status_color}20;
      color: {status_color};
      font-size: 12px;
      font-weight: 700;
      padding: 4px 14px;
      border-radius: 9999px;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      border: 1px solid {status_color}50;
    }}
    .amount-hero {{
      text-align: center;
      padding: 24px 20px 16px 20px;
      border-bottom: 1px dashed #CBD5E1;
    }}
    .amount-hero .label {{
      font-size: 12px;
      text-transform: uppercase;
      letter-spacing: 1px;
      color: #64748B;
      font-weight: 600;
    }}
    .amount-hero .value {{
      font-size: 36px;
      font-weight: 800;
      color: #0A1128;
      margin-top: 4px;
    }}
    .body-content {{
      padding: 24px;
    }}
    .row {{
      display: flex;
      justify-content: space-between;
      margin-bottom: 14px;
      font-size: 14px;
    }}
    .row .label {{
      color: #64748B;
    }}
    .row .value {{
      font-weight: 600;
      color: #0F172A;
      text-align: right;
    }}
    .divider {{
      border-top: 1px solid #E2E8F0;
      margin: 18px 0;
    }}
    .seal-box {{
      background: #F1F5F9;
      padding: 12px;
      border-radius: 8px;
      font-size: 11px;
      color: #475569;
      word-break: break-all;
      margin-top: 20px;
    }}
    .seal-title {{
      font-weight: 700;
      color: #334155;
      margin-bottom: 4px;
    }}
    .footer {{
      background: #F8FAFC;
      padding: 16px 24px;
      text-align: center;
      font-size: 12px;
      color: #94A3B8;
      border-top: 1px solid #E2E8F0;
    }}
    .btn-print {{
      display: block;
      width: calc(100% - 48px);
      margin: 0 24px 24px 24px;
      padding: 12px;
      background: #0066FF;
      color: #FFFFFF;
      text-align: center;
      text-decoration: none;
      font-weight: 600;
      border-radius: 10px;
      cursor: pointer;
      border: none;
      font-size: 14px;
    }}
    @media print {{
      body {{
        background: #FFFFFF;
        padding: 0;
      }}
      .receipt-card {{
        box-shadow: none;
        border: none;
      }}
      .btn-print {{
        display: none;
      }}
    }}
  </style>
</head>
<body>
  <div class="receipt-card">
    <div class="header">
      <h1>PayNora</h1>
      <p>Official Transaction Receipt</p>
      <div class="status-badge">{r['status']}</div>
    </div>

    <div class="amount-hero">
      <div class="label">Total Amount Sent</div>
      <div class="value">{fin['source_currency']} {fin['send_amount']}</div>
    </div>

    <div class="body-content">
      <div class="row">
        <span class="label">Receipt Number</span>
        <span class="value">{r['receipt_number']}</span>
      </div>
      <div class="row">
        <span class="label">Transaction Reference</span>
        <span class="value">{r['transaction_reference']}</span>
      </div>
      <div class="row">
        <span class="label">Date & Time</span>
        <span class="value">{r['timestamp']}</span>
      </div>
      
      <div class="divider"></div>

      <div class="row">
        <span class="label">Recipient Name</span>
        <span class="value">{r['recipient']['name']}</span>
      </div>
      <div class="row">
        <span class="label">Destination Country</span>
        <span class="value">{r['recipient']['destination_country']}</span>
      </div>
      <div class="row">
        <span class="label">Payout Method</span>
        <span class="value">{r['recipient']['payout_method']}</span>
      </div>

      <div class="divider"></div>

      <div class="row">
        <span class="label">Transfer Fee</span>
        <span class="value">{fin['source_currency']} {fin['transfer_fee']}</span>
      </div>
      <div class="row">
        <span class="label">Total Charged</span>
        <span class="value">{fin['source_currency']} {fin['total_charged']}</span>
      </div>
      <div class="row">
        <span class="label">Payment Network</span>
        <span class="value">{fin['gateway_routing']}</span>
      </div>

      <div class="seal-box">
        <div class="seal-title">&#128274; Tamper-Evident Security Seal:</div>
        <code>{r['security_seal']}</code>
      </div>
    </div>

    <button class="btn-print" onclick="window.print()">Download / Print PDF Receipt</button>

    <div class="footer">
      PayNora Global Inc. &bull; support@paynora.com &bull; End-to-end encrypted transfer
    </div>
  </div>
</body>
</html>"""
        return html
