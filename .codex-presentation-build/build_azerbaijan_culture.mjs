import fs from "node:fs/promises";
import path from "node:path";
import crypto from "node:crypto";
import { pathToFileURL } from "node:url";
import { FileBlob, PresentationFile } from "@oai/artifact-tool";

const workspaceDir = "/Users/aminmammadov/giti/Coffe_nvim";
const SKILL_DIR = "/Users/aminmammadov/.codex/plugins/cache/openai-primary-runtime/presentations/26.905.11957/skills/presentations";
const RUNTIME_PYTHON = "/Users/aminmammadov/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3";
const sourcePath = "/Users/aminmammadov/.codex/plugins/cache/openai-curated-remote/openai-templates/0.1.1/skills/artifact-template-team-alignment/assets/reference.pptx";
const buildDir = path.join(workspaceDir, ".codex-presentation-build", "azerbaijan-culture");
const renderDir = path.join(buildDir, "rendered");
const outputDir = path.join(workspaceDir, "artifacts");
const FINAL_PPTX = path.join(outputDir, "Azerbaycan_medeniyyeti_v2.pptx");

const assets = {
  mugham: "/Users/aminmammadov/Desktop/1.png",
  carpets: "/Users/aminmammadov/Desktop/46161_6091a819d7439.png",
  kelaghayi: "/Users/aminmammadov/Desktop/1694067163_-5461094979389738181_121.png",
  weaving: "/Users/aminmammadov/Desktop/carpet_making_heritage_icon_01-article_thumb.png",
  cuisine: "/Users/aminmammadov/Desktop/D091D0B5D0B720D0BDD0B0D0B7D0B2D0B0D0BDD0B8D18F203jpg-1707211613.png",
  instruments: "/Users/aminmammadov/Desktop/library_ph2.png",
  dance: "/Users/aminmammadov/Desktop/reqs.png",
  novruz: "/Users/aminmammadov/Desktop/35551.png",
};

const urls = {
  state: "https://ich.unesco.org/en/state/azerbaijan-AZ?info=elements-on-the-lists",
  mugham: "https://ich.unesco.org/en/RL/azerbaijani-mugham-00039?RL=00039",
  carpet: "https://ich.unesco.org/en/RL/traditional-art-of-azerbaijani-carpet-weaving-in-the-republic-of-azerbaijan-00389?RL=00389",
  kelaghayi: "https://ich.unesco.org/en/RL/traditional-art-and-symbolism-of-kelaghayi-making-and-wearing-women-s-silk-headscarves-00669",
  novruz: "https://ich.unesco.org/en/RL/nawrouz-novruz-nowrouz-nowrouz-nawrouz-nauryz-nooruz-nowruz-navruz-nevruz-nowruz-navruz-02097",
  tea: "https://ich.unesco.org/en/RL/culture-of-cay-tea-a-symbol-of-identity-hospitality-and-social-interaction-01685?RL=01685",
  travelTea: "https://azerbaijan.travel/lankaran-tea",
  dolma: "https://ich.unesco.org/en/RL/dolma-making-and-sharing-tradition-a-marker-of-cultural-identity-01188",
  yalli: "https://ich.unesco.org/en/USL/kochari-traditional-group-dances-of-armenia-01190",
  tar: "https://ich.unesco.org/en/RL/craftsmanship-and-performance-art-of-the-tar-a-long-necked-string-musical-instrument-00671?RL=00671",
  kamancha: "https://ich.unesco.org/en/RL/art-of-crafting-and-playing-with-kamantcheh-kamancha-a-bowed-string-musical-instrument-01286",
};

const COLORS = { teal: "#0B4158", text: "#273E48", blue: "#179FE3", muted: "#63727A" };

await fs.mkdir(buildDir, { recursive: true });
await fs.mkdir(renderDir, { recursive: true });
await fs.mkdir(outputDir, { recursive: true });

const presentation = await PresentationFile.importPptx(await FileBlob.load(sourcePath));

// Retain and reuse the reference slides that best fit the cultural narrative.
const cover = presentation.slides.getItem(0);
const halfImage = presentation.slides.getItem(4);
const wideImage = presentation.slides.getItem(5);
const intro = presentation.slides.getItem(12);
const timeline = presentation.slides.getItem(13);
const threeColumns = presentation.slides.getItem(16);
const closing = presentation.slides.getItem(23);

const carpet = halfImage.duplicate();
const kelaghayi = halfImage.duplicate();
const novruz = halfImage.duplicate();

const keep = [cover, intro, halfImage, carpet, kelaghayi, novruz, wideImage, threeColumns, timeline, closing];
const keepIds = new Set(keep.map((slide) => slide.id));
for (const slide of [...presentation.slides.items]) {
  if (!keepIds.has(slide.id)) slide.delete();
}
keep.forEach((slide, index) => slide.moveTo(index));

const setShapeText = (shape, text, { size = 14, bold = false, color = COLORS.text, align = "left", valign = "top" } = {}) => {
  shape.text = text;
  shape.text.style = {
    typeface: "Inter",
    fontSizePt: size,
    bold,
    color,
    alignment: align,
    verticalAlignment: valign,
    autoFit: "shrinkText",
    wrap: true,
  };
};

const setRichBlock = (shape, heading, paragraphs, { headingSize = 18, bodySize = 13.5 } = {}) => {
  shape.text = [
    {
      runs: [{ run: heading, textStyle: { typeface: "Inter", fontSize: `${headingSize}pt`, bold: true, color: COLORS.teal } }],
      spaceAfter: 900,
    },
    ...paragraphs.map((p, index) => ({
      runs: [{ run: p, textStyle: { typeface: "Inter", fontSize: `${bodySize}pt`, color: COLORS.text } }],
      spaceAfter: index === paragraphs.length - 1 ? 0 : 800,
    })),
  ];
  shape.text.style = { autoFit: "shrinkText", wrap: true, verticalAlignment: "top" };
};

const replaceImage = async (slide, image, filePath, alt, fit = "cover") => {
  const bytes = new Uint8Array(await fs.readFile(filePath));
  const frame = image.frame;
  const geometry = image.geometry;
  const radius = image.borderRadius;
  image.delete();
  const inserted = slide.images.add({
    blob: bytes,
    contentType: "image/png",
    alt,
    fit,
    position: frame,
    geometry,
    ...(radius ? { borderRadius: radius } : {}),
  });
  inserted.lockAspectRatio = true;
  return inserted;
};

const note = (slide, lines) => {
  slide.speakerNotes.text = lines.join("\n");
};

// 1. Cover
setShapeText(cover.shapes.items[0], "Azərbaycan\nmədəniyyəti", { size: 42, bold: true, color: COLORS.teal });
setShapeText(cover.shapes.items[1], "Ənənə, sənət və gündəlik həyat", { size: 17, color: COLORS.text });
note(cover, ["Təqdimat Team Alignment şablonu əsasında hazırlanıb."]);

// 2. Cultural crossroads
setShapeText(intro.shapes.items[1], "Mədəniyyətlərin qovşağı", { size: 31, bold: true, color: COLORS.teal });
setRichBlock(intro.shapes.items[10], "Canlı və çoxqatlı irs", [
  "Azərbaycan mədəniyyəti türk dünyası, islam sivilizasiyası və Qafqazın çoxsəsli mühitində formalaşıb.",
  "Bu irs musiqidə improvizasiya, sənətdə naxış, süfrədə paylaşma, bayramlarda isə birlik kimi yaşayır.",
], { headingSize: 19, bodySize: 13.5 });
const introItems = [
  ["Musiqi", "Muğam, aşıq sənəti və xalq alətləri"],
  ["Sənətkarlıq", "Xalça, kəlağayı, ipək və təbii boyalar"],
  ["Mərasim", "Novruz, çay süfrəsi və qonaqpərvərlik"],
  ["Mətbəx", "Plov, dolma, təndir çörəyi və şirniyyatlar"],
];
for (let i = 0; i < introItems.length; i += 1) {
  setShapeText(intro.shapes.items[3 + i * 2], introItems[i][0], { size: 14, bold: true, color: COLORS.blue });
  setShapeText(intro.shapes.items[2 + i * 2], introItems[i][1], { size: 12.5, color: COLORS.text });
}
note(intro, ["Mənbə:", urls.state]);

// 3. Mugham
setShapeText(halfImage.shapes.items[2], "Muğam", { size: 31, bold: true, color: COLORS.teal });
setRichBlock(halfImage.shapes.items[0], "İmprovizasiya üzərində qurulan klassik sənət", [
  "Xanəndə melodik xətti tar, kamança və qavalın müşayiəti ilə sərbəst inkişaf etdirir. Eyni muğam hər ifada yeni çalar qazana bilər.",
  "UNESCO Azərbaycan muğamını 2008-ci ildə Bəşəriyyətin Qeyri-maddi Mədəni İrsinin Reprezentativ Siyahısına daxil edib.",
]);
await replaceImage(halfImage, halfImage.images.items[0], assets.mugham, "Azərbaycan muğam ifaçıları və ənənəvi musiqi alətləri");
note(halfImage, ["Mənbə:", urls.mugham, "Şəkil: istifadəçi tərəfindən təqdim edilib."]);

// 4. Carpet weaving
setShapeText(carpet.shapes.items[2], "Xalçaçılıq", { size: 31, bold: true, color: COLORS.teal });
setRichBlock(carpet.shapes.items[0], "Naxışlarda yaddaş və məkan", [
  "Qarabağ, Quba, Şirvan, Gəncə, Qazax və Bakı məktəbləri rəng, kompozisiya və ornament dili ilə seçilir.",
  "Yun, pambıq və ipək saplar müxtəlif texnikalarla toxunur. Sənət ailə daxilində müşahidə və təcrübə yolu ilə ötürülür. UNESCO bu ənənəni 2010-cu ildə siyahıya daxil edib.",
], { bodySize: 13 });
await replaceImage(carpet, carpet.images.items[0], assets.carpets, "Azərbaycan xalçalarının muzey ekspozisiyası");
carpet.images.add({
  blob: new Uint8Array(await fs.readFile(assets.weaving)),
  contentType: "image/png",
  alt: "Ənənəvi dəzgahda xalça toxuyan sənətkar",
  fit: "cover",
  geometry: "roundRect",
  borderRadius: "rounded-xl",
  position: { left: 972, top: 438, width: 236, height: 160 },
});
note(carpet, ["Mənbə:", urls.carpet, "Şəkillər: istifadəçi tərəfindən təqdim edilib."]);

// 5. Kelaghayi
setShapeText(kelaghayi.shapes.items[2], "Kəlağayı", { size: 31, bold: true, color: COLORS.teal });
setRichBlock(kelaghayi.shapes.items[0], "İpək üzərində simvol və rəng", [
  "Kəlağayı qəlib, isti mum və boya ilə bəzədilən ənənəvi ipək baş örtüyüdür. Buta, nəbati və həndəsi motivlər onun vizual dilini yaradır.",
  "Sənət xüsusilə Şəki və Basqal ilə bağlıdır. UNESCO kəlağayının hazırlanması və istifadə ənənəsini 2014-cü ildə Reprezentativ Siyahıya daxil edib.",
]);
await replaceImage(kelaghayi, kelaghayi.images.items[0], assets.kelaghayi, "Naxışlı Azərbaycan kəlağayıları");
note(kelaghayi, ["Mənbə:", urls.kelaghayi, "Şəkil: istifadəçi tərəfindən təqdim edilib."]);

// 6. Novruz and hospitality
setShapeText(novruz.shapes.items[2], "Novruz və qonaqpərvərlik", { size: 30, bold: true, color: COLORS.teal });
setRichBlock(novruz.shapes.items[0], "Yenilənmə və birlik mərasimi", [
  "Novruz yazın gəlişini qarşılayır. Səməni, tonqal, bayram süfrəsi, papaqatdı və ailə ziyarətləri təbiətin yenilənməsini ictimai birliklə bağlayır.",
  "Qonağa armudu stəkanda çay, mürəbbə və şirniyyat təqdim etmək hörmət və ünsiyyət ənənəsidir. Azərbaycan və Türkiyənin çay mədəniyyəti UNESCO siyahısına 2022-ci ildə daxil edilib.",
], { bodySize: 12.8 });
await replaceImage(novruz, novruz.images.items[0], assets.novruz, "Novruz süfrəsi, xalq rəqsi və sənətkarlıq nümunələri");
note(novruz, ["Mənbələr:", urls.novruz, urls.tea, urls.travelTea, "Şəkil: istifadəçi tərəfindən təqdim edilib."]);

// 7. Cuisine
setShapeText(wideImage.shapes.items[2], "Azərbaycan mətbəxi", { size: 31, bold: true, color: COLORS.teal });
setRichBlock(wideImage.shapes.items[0], "Süfrə paylaşma mədəniyyətidir", [
  "Plov zəfəranlı düyü, qazmaq və ayrıca hazırlanan qara ilə təqdim olunur. Bölgələrə görə tərkibi və servis üslubu dəyişir.",
  "Dolmada içlik yarpağa bükülür və ya tərəvəzə doldurulur. UNESCO dolma hazırlama və paylaşma ənənəsini 2017-ci ildə siyahıya daxil edib.",
  "Paxlava, şəkərbura və qoğal xüsusilə Novruz süfrəsinin tanınan şirniyyatlarıdır.",
], { headingSize: 18, bodySize: 12.5 });
await replaceImage(wideImage, wideImage.images.items[0], assets.cuisine, "Azərbaycan mətbəxindən plov, dolma, kabab, qutab və şirniyyatlar");
note(wideImage, ["Mənbə:", urls.dolma, "Şəkil: istifadəçi tərəfindən təqdim edilib."]);

// 8. Dance and instruments
setShapeText(threeColumns.shapes.items[4], "Xalq rəqsləri və musiqi alətləri", { size: 31, bold: true, color: COLORS.teal });
setRichBlock(threeColumns.shapes.items[0], "Yallı", [
  "İştirakçılar dairə, zəncir və ya sıra şəklində birlikdə hərəkət edirlər. Naxçıvanın yallı ənənəsi 2018-ci ildən UNESCO-nun Təcili Qorunmaya Ehtiyacı Olan İrs Siyahısındadır.",
], { headingSize: 17, bodySize: 12.2 });
setRichBlock(threeColumns.shapes.items[2], "Tar", [
  "Uzunqollu simli alət muğamın əsas səs dayaqlarındandır. Azərbaycanda tarın hazırlanması və ifa sənəti 2012-ci ildə UNESCO siyahısına daxil edilib.",
], { headingSize: 17, bodySize: 12.2 });
threeColumns.shapes.items[3].position = { left: 864.28, top: 154, width: 374.67, height: 475 };
threeColumns.shapes.items[3].text = [
  { runs: [{ run: "4 simli", textStyle: { typeface: "Inter", fontSize: "30pt", bold: true, color: COLORS.blue } }], spaceAfter: 1000 },
  { runs: [{ run: "Kamança", textStyle: { typeface: "Inter", fontSize: "18pt", bold: true, color: COLORS.teal } }], spaceAfter: 900 },
  { runs: [{ run: "Yayla ifa olunan kamança klassik və folklor musiqisində mühüm yer tutur. Azərbaycan və İran bu sənəti 2017-ci ildə UNESCO siyahısına birgə təqdim edib.", textStyle: { typeface: "Inter", fontSize: "13pt", color: COLORS.text } }] },
];
threeColumns.shapes.items[3].text.style = { autoFit: "shrinkText", wrap: true, verticalAlignment: "top" };
const originalDanceImages = [...threeColumns.images.items];
await replaceImage(threeColumns, originalDanceImages[0], assets.dance, "Azərbaycan xalq rəqsi ifaçıları");
await replaceImage(threeColumns, originalDanceImages[1], assets.instruments, "Tar, kamança, qaval və nağara kimi Azərbaycan musiqi alətləri");
originalDanceImages[2].delete();
note(threeColumns, ["Mənbələr:", urls.yalli, urls.tar, urls.kamancha, "Şəkillər: istifadəçi tərəfindən təqdim edilib."]);

// 9. UNESCO timeline
setShapeText(timeline.shapes.items[2], "UNESCO siyahısında Azərbaycan irsi", { size: 31, bold: true, color: COLORS.teal });
const milestones = [
  ["2008", "Muğam", "İmprovizasiya və ustad-şagird ənənəsi beynəlxalq səviyyədə tanındı."],
  ["2010", "Xalçaçılıq", "Toxuculuq bilikləri, regional naxışlar və ailədaxili ötürmə qeyd edildi."],
  ["2014", "Kəlağayı", "Şəki və Basqal ipəkçiliyinin sənətkarlıq və simvolika irsi siyahıya daxil edildi."],
];
for (let i = 0; i < 3; i += 1) {
  setShapeText(timeline.shapes.items[9 + i], milestones[i][0], { size: 13, bold: true, color: COLORS.blue });
  setRichBlock(timeline.shapes.items[[0, 3, 4][i]], milestones[i][1], [milestones[i][2]], { headingSize: 17, bodySize: 12.2 });
}
note(timeline, ["Mənbə:", urls.state, "Sonrakı nümunələrə 2017-ci ildə dolma və kamança, 2018-ci ildə isə yallı ilə bağlı qərar daxildir."]);

// 10. Closing
setShapeText(closing.shapes.items[0], "Təşəkkürlər", { size: 42, bold: true, color: COLORS.teal });
setShapeText(closing.shapes.items[1], "Azərbaycan mədəniyyəti canlı irsdir", { size: 17, color: COLORS.text });
note(closing, ["Əsas mənbə:", urls.state]);

const snapshot = await presentation.inspect({ kind: "slide,textbox,image,notes,layout", maxChars: 30000 });
await fs.writeFile(path.join(buildDir, "final-inspect.ndjson"), snapshot.ndjson);

for (let i = 0; i < presentation.slides.items.length; i += 1) {
  const slide = presentation.slides.getItem(i);
  const png = await slide.export({ format: "png", scale: 1 });
  await fs.writeFile(path.join(renderDir, `slide-${String(i + 1).padStart(2, "0")}.png`), new Uint8Array(await png.arrayBuffer()));
  const layout = await slide.export({ format: "layout" });
  await fs.writeFile(path.join(renderDir, `slide-${String(i + 1).padStart(2, "0")}.layout.json`), await layout.text());
}
const montage = await presentation.export({ format: "png", montage: { format: "png", columns: 2, slideWidth: 640, padding: 12, gap: 12, background: "#E8EEF1" }, scale: 0.5 });
await fs.writeFile(path.join(renderDir, "montage.png"), new Uint8Array(await montage.arrayBuffer()));

const referenceBytes = await fs.readFile(sourcePath);
const referenceSha256 = crypto.createHash("sha256").update(referenceBytes).digest("hex");
const { finalizePresentation } = await import(pathToFileURL(path.join(SKILL_DIR, "container_tools/artifact_tool_utils.mjs")).href);
const stagingDir = path.join(workspaceDir, ".codex-finalizer");
await fs.mkdir(stagingDir, { recursive: true });
const candidatePath = path.join(stagingDir, "azerbaijan-culture-candidate.pptx");
await (await PresentationFile.exportPptx(presentation)).save(candidatePath);

const result = await finalizePresentation({
  explicitTotalSlideCount: 10,
  requiredNativeTableOwnerSlides: [],
  requiredNativeChartOwnerSlides: [],
  sourceTemplatePath: sourcePath,
  workspaceDir,
  candidatePath,
  finalPath: FINAL_PPTX,
  pythonExecutable: RUNTIME_PYTHON,
  integrityValidatorPath: path.join(SKILL_DIR, "container_tools/inspect_presentation_package_integrity.py"),
  layoutValidatorPath: path.join(SKILL_DIR, "container_tools/inspect_presentation_layout_geometry.py"),
  layoutArgs: [
    "--expected-slide-size-emu", "12192000,6858000",
    "--validate-bullet-geometry",
    "--validate-heading-fit",
  ],
  fontPolicy: {
    basis: "reference",
    families: ["Inter"],
    referencePath: sourcePath,
    referenceSha256,
  },
  verifyArtifactToolImport: true,
  receiptPath: path.join(stagingDir, "Azerbaycan_medeniyyeti_v2.validation.json"),
});

console.log(JSON.stringify({ finalPath: FINAL_PPTX, result }, null, 2));
