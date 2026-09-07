import fs from "node:fs/promises";
import { FileBlob, PresentationFile } from "@oai/artifact-tool";

const sourcePath = "/Users/aminmammadov/.codex/plugins/cache/openai-curated-remote/openai-templates/0.1.1/skills/artifact-template-team-alignment/assets/reference.pptx";
const outDir = "/Users/aminmammadov/giti/Coffe_nvim/.codex-presentation-build/template-render";
await fs.mkdir(outDir, { recursive: true });
const presentation = await PresentationFile.importPptx(await FileBlob.load(sourcePath));
const snapshot = await presentation.inspect({
  kind: "deck,slide,textbox,shape,image,table,chart,layout",
  include: "id,slide,name,title,text,textPreview,bbox,bboxUnit,alt,isPlaceholder,placeholders",
  maxChars: 50000,
});
await fs.writeFile(`${outDir}/inspect.ndjson`, snapshot.ndjson);
for (let i = 0; i < presentation.slides.items.length; i += 1) {
  const slide = presentation.slides.getItem(i);
  const png = await slide.export({ format: "png", scale: 1 });
  await fs.writeFile(`${outDir}/slide-${String(i + 1).padStart(2, "0")}.png`, new Uint8Array(await png.arrayBuffer()));
  const layout = await slide.export({ format: "layout" });
  await fs.writeFile(`${outDir}/slide-${String(i + 1).padStart(2, "0")}.layout.json`, await layout.text());
}
const montage = await presentation.export({ format: "png", montage: true, scale: 0.5 });
await fs.writeFile(`${outDir}/montage.png`, new Uint8Array(await montage.arrayBuffer()));
console.log(JSON.stringify({
  slides: presentation.slides.items.length,
  masters: presentation.masters.items.map((m) => ({ id: m.id, name: m.name })),
  layouts: presentation.layouts.items.map((l) => ({ id: l.id, name: l.name, placeholders: l.placeholders.summary() })),
}, null, 2));
