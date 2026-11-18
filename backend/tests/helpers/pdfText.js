// Reads the text of a PDF for the tests.
//
// pdf-parse (pdfjs) loads its worker with a dynamic import(), which Jest's sandbox does
// not allow. So the text is extracted in a separate, normal Node process:
//   pdfText(buffer)  → runs this same file with the PDF on stdin and returns its text.
const { execFileSync } = require('child_process');

/** Text of the PDF with line breaks turned into spaces (justified text wraps anywhere). */
function pdfText(buffer) {
  const output = execFileSync(process.execPath, [__filename], {
    input: buffer,
    maxBuffer: 10 * 1024 * 1024,
  });
  return output.toString('utf8').replace(/\s+/g, ' ');
}

async function main() {
  const { PDFParse } = require('pdf-parse');
  const chunks = [];
  for await (const chunk of process.stdin) chunks.push(chunk);
  const parser = new PDFParse({ data: new Uint8Array(Buffer.concat(chunks)) });
  try {
    process.stdout.write((await parser.getText()).text);
  } finally {
    await parser.destroy();
  }
}

if (require.main === module) {
  main().catch((err) => {
    process.stderr.write(`pdfText: ${err.message}\n`);
    process.exit(1);
  });
}

module.exports = { pdfText };
