import { FileBlob, PresentationFile } from "@oai/artifact-tool";

const sourcePath = "/Users/aminmammadov/.codex/plugins/cache/openai-curated-remote/openai-templates/0.1.1/skills/artifact-template-team-alignment/assets/reference.pptx";
const presentation = await PresentationFile.importPptx(await FileBlob.load(sourcePath));
for (const query of ["remove slide delete slide", "duplicate slide moveTo", "clear slide shapes delete element", "slide collection removeAt"]) {
  const help = presentation.help(query, { include: ["index", "examples", "notes"], maxChars: 12000 });
  console.log(`QUERY ${query}\n${JSON.stringify(help, null, 2)}\n`);
}
