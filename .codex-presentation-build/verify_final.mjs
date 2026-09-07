import fs from "node:fs/promises";
import { FileBlob, PresentationFile } from "@oai/artifact-tool";

const sourcePath = "/Users/aminmammadov/giti/Coffe_nvim/artifacts/Azerbaycan_medeniyyeti_v2.pptx";
const outDir = "/Users/aminmammadov/giti/Coffe_nvim/.codex-presentation-build/final-verification";
await fs.mkdir(outDir, { recursive: true });
const presentation = await PresentationFile.importPptx(await FileBlob.load(sourcePath));
for (let i = 0; i < presentation.slides.items.length; i += 1) {
  const slide = presentation.slides.getItem(i);
  const png = await slide.export({ format: "png", scale: 1 });
  await fs.writeFile(`${outDir}/slide-${String(i + 1).padStart(2, "0")}.png`, new Uint8Array(await png.arrayBuffer()));
}
const montage = await presentation.export({
  format: "png",
  montage: { format: "png", columns: 2, slideWidth: 640, padding: 12, gap: 12, background: "#E8EEF1" },
  scale: 0.5,
});
await fs.writeFile(`${outDir}/montage.png`, new Uint8Array(await montage.arrayBuffer()));
const inspection = await presentation.inspect({ kind: "deck,slide,textbox,image,notes", maxChars: 50000 });
await fs.writeFile(`${outDir}/inspect.ndjson`, inspection.ndjson);
console.log(JSON.stringify({ slides: presentation.slides.items.length, images: inspection.ndjson.split("\n").filter((line) => line.includes('"kind":"image"')).length }, null, 2));
