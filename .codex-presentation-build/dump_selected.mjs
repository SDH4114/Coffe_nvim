import { FileBlob, PresentationFile } from "@oai/artifact-tool";
const sourcePath = "/Users/aminmammadov/.codex/plugins/cache/openai-curated-remote/openai-templates/0.1.1/skills/artifact-template-team-alignment/assets/reference.pptx";
const presentation = await PresentationFile.importPptx(await FileBlob.load(sourcePath));
for (const n of [14]) {
  const slide = presentation.slides.getItem(n-1);
  console.log(`\nSLIDE ${n}`);
  console.log(JSON.stringify({
    shapes: slide.shapes.items.map((s, i) => ({i,id:s.id,name:s.name,geometry:s.geometry,position:s.position,text:s.text?.toString?.() ?? null,style:s.text?.style ?? null,fill:s.fill,line:s.line})),
    images: slide.images.items.map((im,i)=>({i,id:im.id,name:im.name,frame:im.frame,fit:im.fit,crop:im.crop,geometry:im.geometry,alt:im.alt})),
    placeholders: slide.placeholders.summary(),
  }, null, 2));
}
