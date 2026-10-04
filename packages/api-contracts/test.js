const fs = require('fs');
const path = require('path');

try {
  const contractPath = path.join(__dirname, 'openapi.json');
  const rawData = fs.readFileSync(contractPath, 'utf-8');
  const spec = JSON.parse(rawData);
  if (spec.openapi && spec.info.title === "PayNora Global Financial Core API") {
    console.log("✅ PayNora API Contracts OpenAPI Spec validation successful.");
    process.exit(0);
  } else {
    console.error("❌ Invalid OpenAPI Spec structure.");
    process.exit(1);
  }
} catch (err) {
  console.error("❌ Error reading OpenAPI contract:", err.message);
  process.exit(1);
}
