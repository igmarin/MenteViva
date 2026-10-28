# Art prompt log

Append one row for every selected production picture: slug, complete submitted
prompt, generation date and actual tool/model/version disclosure. A prompt-file
link is acceptable when it contains the exact submitted text. Do not invent a
model/version that the tool does not expose. See [style](design/art-style.md) and
[provenance](ip-clearance.md#ai-generated-pictures).

## Concept studies (not catalogue assets)

| Study | Exact prompt | Date | Tool / model / version |
|---|---|---|---|
| Owner-approved retro direction | [Prompt](design/art-samples/retro-direction-approved.prompt.txt) | 2026-10-27 | OpenAI built-in image-generation tool in Codex; model/version not exposed |

## Production pictures

The #328 prompts ask for a plain pure white background (as the #323 violin sample did); the white was then flood-filled to transparent, cropped and fitted to 600×600 with Pillow. The "subtle friendly face" sentence of the fixed paragraph is dropped because none of these objects has a face.

| Slug | Prompt | Date | Tool / model / version |
|---|---|---|---|
| apple (sample, #323; revised 2026-10-28 to match approved sheet) | [Prompt](design/art-samples/prompts/apple.prompt.txt) | 2026-10-28 | Muse built-in image generation (`muse.image_generation`); model/version not exposed |
| sunflower (sample, #323) | [Prompt](design/art-samples/prompts/sunflower.prompt.txt) | 2026-10-28 | Muse built-in image generation (`muse.image_generation`); model/version not exposed |
| key (sample, #323) | [Prompt](design/art-samples/prompts/key.prompt.txt) | 2026-10-28 | Muse built-in image generation (`muse.image_generation`); model/version not exposed |
| sailboat (sample, #323) | [Prompt](design/art-samples/prompts/sailboat.prompt.txt) | 2026-10-28 | Muse built-in image generation (`muse.image_generation`); model/version not exposed |
| violin (sample, #323) | [Prompt](design/art-samples/prompts/violin.prompt.txt) | 2026-10-28 | Muse built-in image generation (`muse.image_generation`); model/version not exposed |
| moon (sample, #323; revised 2026-10-28 to match approved sheet) | [Prompt](design/art-samples/prompts/moon.prompt.txt) | 2026-10-28 | Muse built-in image generation (`muse.image_generation`); model/version not exposed |
| map (#328) | [Prompt](design/art-samples/prompts/pic.map.prompt.txt) | 2026-10-28 | Codex CLI 0.165.0 built-in image generation tool (`codex exec`); model/version not exposed |
| suitcase (#328) | [Prompt](design/art-samples/prompts/pic.suitcase.prompt.txt) | 2026-10-28 | Codex CLI 0.165.0 built-in image generation tool (`codex exec`); model/version not exposed |
| mountain (#328) | [Prompt](design/art-samples/prompts/pic.mountain.prompt.txt) | 2026-10-28 | Codex CLI 0.165.0 built-in image generation tool (`codex exec`); model/version not exposed |
| beach (#328) | [Prompt](design/art-samples/prompts/pic.beach.prompt.txt) | 2026-10-28 | Codex CLI 0.165.0 built-in image generation tool (`codex exec`); model/version not exposed |
| tent (#328) | [Prompt](design/art-samples/prompts/pic.tent.prompt.txt) | 2026-10-28 | Codex CLI 0.165.0 built-in image generation tool (`codex exec`); model/version not exposed |
| lighthouse (#328) | [Prompt](design/art-samples/prompts/pic.lighthouse.prompt.txt) | 2026-10-28 | Codex CLI 0.165.0 built-in image generation tool (`codex exec`); model/version not exposed |
| helicopter (#328) | [Prompt](design/art-samples/prompts/pic.helicopter.prompt.txt) | 2026-10-28 | Codex CLI 0.165.0 built-in image generation tool (`codex exec`); model/version not exposed |
| trumpet (#328) | [Prompt](design/art-samples/prompts/pic.trumpet.prompt.txt) | 2026-10-28 | Codex CLI 0.165.0 built-in image generation tool (`codex exec`); model/version not exposed |
| piano (#328) | [Prompt](design/art-samples/prompts/pic.piano.prompt.txt) | 2026-10-28 | Codex CLI 0.165.0 built-in image generation tool (`codex exec`); model/version not exposed |
| radio (#328) | [Prompt](design/art-samples/prompts/pic.radio.prompt.txt) | 2026-10-28 | Codex CLI 0.165.0 built-in image generation tool (`codex exec`); model/version not exposed |
| yarn (#328) | [Prompt](design/art-samples/prompts/pic.yarn.prompt.txt) | 2026-10-28 | Codex CLI 0.165.0 built-in image generation tool (`codex exec`); model/version not exposed |
| accordion (#328) | [Prompt](design/art-samples/prompts/pic.accordion.prompt.txt) | 2026-10-28 | Codex CLI 0.165.0 built-in image generation tool (`codex exec`); model/version not exposed |
| picture_frame (#328) | [Prompt](design/art-samples/prompts/pic.picture_frame.prompt.txt) | 2026-10-28 | Codex CLI 0.165.0 built-in image generation tool (`codex exec`); model/version not exposed |
| telephone (#328) | [Prompt](design/art-samples/prompts/pic.telephone.prompt.txt) | 2026-10-28 | Codex CLI 0.165.0 built-in image generation tool (`codex exec`); model/version not exposed |
| sofa (#328) | [Prompt](design/art-samples/prompts/pic.sofa.prompt.txt) | 2026-10-28 | Codex CLI 0.165.0 built-in image generation tool (`codex exec`); model/version not exposed |
| violin (#328; reused unchanged from the #323 sample, not regenerated) | [Prompt](design/art-samples/prompts/violin.prompt.txt) | 2026-10-28 | Muse built-in image generation (`muse.image_generation`); model/version not exposed |
| teapot (reused from the #323 sample, #327; no new generation) | [Prompt](design/art-samples/prompts/teapot.prompt.txt) | 2026-10-28 | Muse built-in image generation (`muse.image_generation`); model/version not exposed |
| bread (#327) | [Prompt](design/art-samples/prompts/bread.prompt.txt) | 2026-10-28 | OpenAI built-in image-generation tool driven through `codex exec` (codex-cli 0.165.0); image model/version not exposed |
| cheese (#327) | [Prompt](design/art-samples/prompts/cheese.prompt.txt) | 2026-10-28 | OpenAI built-in image-generation tool driven through `codex exec` (codex-cli 0.165.0); image model/version not exposed |
| wine_glass (#327) | [Prompt](design/art-samples/prompts/wine_glass.prompt.txt) | 2026-10-28 | OpenAI built-in image-generation tool driven through `codex exec` (codex-cli 0.165.0); image model/version not exposed |
| croissant (#327) | [Prompt](design/art-samples/prompts/croissant.prompt.txt) | 2026-10-28 | OpenAI built-in image-generation tool driven through `codex exec` (codex-cli 0.165.0); image model/version not exposed |
| lemon (#327; second generation, tilted to tell it from egg in grayscale; first try discarded) | [Prompt](design/art-samples/prompts/lemon.prompt.txt) | 2026-10-28 | OpenAI built-in image-generation tool driven through `codex exec` (codex-cli 0.165.0); image model/version not exposed |
| olives (#327) | [Prompt](design/art-samples/prompts/olives.prompt.txt) | 2026-10-28 | OpenAI built-in image-generation tool driven through `codex exec` (codex-cli 0.165.0); image model/version not exposed |
| honey (#327) | [Prompt](design/art-samples/prompts/honey.prompt.txt) | 2026-10-28 | OpenAI built-in image-generation tool driven through `codex exec` (codex-cli 0.165.0); image model/version not exposed |
| cake (#327) | [Prompt](design/art-samples/prompts/cake.prompt.txt) | 2026-10-28 | OpenAI built-in image-generation tool driven through `codex exec` (codex-cli 0.165.0); image model/version not exposed |
| chocolate (#327) | [Prompt](design/art-samples/prompts/chocolate.prompt.txt) | 2026-10-28 | OpenAI built-in image-generation tool driven through `codex exec` (codex-cli 0.165.0); image model/version not exposed |
| egg (#327) | [Prompt](design/art-samples/prompts/egg.prompt.txt) | 2026-10-28 | OpenAI built-in image-generation tool driven through `codex exec` (codex-cli 0.165.0); image model/version not exposed |
| rose (#327) | [Prompt](design/art-samples/prompts/rose.prompt.txt) | 2026-10-28 | OpenAI built-in image-generation tool driven through `codex exec` (codex-cli 0.165.0); image model/version not exposed |
| tulip (#327) | [Prompt](design/art-samples/prompts/tulip.prompt.txt) | 2026-10-28 | OpenAI built-in image-generation tool driven through `codex exec` (codex-cli 0.165.0); image model/version not exposed |
| potted_plant (#327) | [Prompt](design/art-samples/prompts/potted_plant.prompt.txt) | 2026-10-28 | OpenAI built-in image-generation tool driven through `codex exec` (codex-cli 0.165.0); image model/version not exposed |
| pear (#327) | [Prompt](design/art-samples/prompts/pear.prompt.txt) | 2026-10-28 | OpenAI built-in image-generation tool driven through `codex exec` (codex-cli 0.165.0); image model/version not exposed |
| tree (#327) | [Prompt](design/art-samples/prompts/tree.prompt.txt) | 2026-10-28 | OpenAI built-in image-generation tool driven through `codex exec` (codex-cli 0.165.0); image model/version not exposed |
| pine (#327) | [Prompt](design/art-samples/prompts/pine.prompt.txt) | 2026-10-28 | OpenAI built-in image-generation tool driven through `codex exec` (codex-cli 0.165.0); image model/version not exposed |
| ladybug (#327) | [Prompt](design/art-samples/prompts/ladybug.prompt.txt) | 2026-10-28 | OpenAI built-in image-generation tool driven through `codex exec` (codex-cli 0.165.0); image model/version not exposed |

**#327 processing disclosure (all 17 new pictures, not teapot):** the generated image was submitted on plain white with the prompt file's exact text; the picture was then cut out in code (white background flood-filled from the edges to transparent), cropped, fitted to 480px, centred on a transparent 600×600 canvas, and given a thin cream (`#FFF1D0`) separation edge about 4px wide so the outline stays visible on the dark tile. The prompt files use the key sample's wording (white background, no face unless the object description says one) because the cutout is made in code, not by the generator. Only the egg has a face. Nothing was traced and no source image was supplied. The contact sheet shows coffee, bee, butterfly, grapes, apple and sunflower from the other batches (#325/#326 working copies, not part of this PR) so each Memory Lane theme can be read whole.
| dog (#325, reuses #323 sample as production) | [Prompt](design/art-samples/prompts/pic.dog.prompt.txt) | 2026-10-28 | Reused from the merged #323 sample (Muse built-in image generation; model/version not exposed); no new generation |
| cat (#325) | [Prompt](design/art-samples/prompts/pic.cat.prompt.txt) | 2026-10-28 | OpenAI built-in image-generation tool driven through `codex exec` (Codex CLI 0.165.0); model/version not exposed. Background removed locally with Pillow |
| lion (#325) | [Prompt](design/art-samples/prompts/pic.lion.prompt.txt) | 2026-10-28 | OpenAI built-in image-generation tool driven through `codex exec` (Codex CLI 0.165.0); model/version not exposed. Background removed locally with Pillow |
| frog (#325) | [Prompt](design/art-samples/prompts/pic.frog.prompt.txt) | 2026-10-28 | OpenAI built-in image-generation tool driven through `codex exec` (Codex CLI 0.165.0); model/version not exposed. Background removed locally with Pillow |
| turtle (#325) | [Prompt](design/art-samples/prompts/pic.turtle.prompt.txt) | 2026-10-28 | OpenAI built-in image-generation tool driven through `codex exec` (Codex CLI 0.165.0); model/version not exposed. Background removed locally with Pillow |
| butterfly (#325) | [Prompt](design/art-samples/prompts/pic.butterfly.prompt.txt) | 2026-10-28 | OpenAI built-in image-generation tool driven through `codex exec` (Codex CLI 0.165.0); model/version not exposed. Background removed locally with Pillow |
| elephant (#325) | [Prompt](design/art-samples/prompts/pic.elephant.prompt.txt) | 2026-10-28 | OpenAI built-in image-generation tool driven through `codex exec` (Codex CLI 0.165.0); model/version not exposed. Background removed locally with Pillow |
| apple (#325, reuses #323 sample as production) | [Prompt](design/art-samples/prompts/pic.apple.prompt.txt) | 2026-10-28 | Reused from the merged #323 sample (Muse built-in image generation; model/version not exposed); no new generation |
| banana (#325) | [Prompt](design/art-samples/prompts/pic.banana.prompt.txt) | 2026-10-28 | OpenAI built-in image-generation tool driven through `codex exec` (Codex CLI 0.165.0); model/version not exposed. Background removed locally with Pillow |
| grapes (#325) | [Prompt](design/art-samples/prompts/pic.grapes.prompt.txt) | 2026-10-28 | OpenAI built-in image-generation tool driven through `codex exec` (Codex CLI 0.165.0); model/version not exposed. Background removed locally with Pillow |
| orange (#325) | [Prompt](design/art-samples/prompts/pic.orange.prompt.txt) | 2026-10-28 | OpenAI built-in image-generation tool driven through `codex exec` (Codex CLI 0.165.0); model/version not exposed. Background removed locally with Pillow |
| strawberry (#325) | [Prompt](design/art-samples/prompts/pic.strawberry.prompt.txt) | 2026-10-28 | OpenAI built-in image-generation tool driven through `codex exec` (Codex CLI 0.165.0); model/version not exposed. Background removed locally with Pillow |
| watermelon (#325) | [Prompt](design/art-samples/prompts/pic.watermelon.prompt.txt) | 2026-10-28 | OpenAI built-in image-generation tool driven through `codex exec` (Codex CLI 0.165.0); model/version not exposed. Background removed locally with Pillow |
| peach (#325) | [Prompt](design/art-samples/prompts/pic.peach.prompt.txt) | 2026-10-28 | OpenAI built-in image-generation tool driven through `codex exec` (Codex CLI 0.165.0); model/version not exposed. Background removed locally with Pillow |
| car (#325) | [Prompt](design/art-samples/prompts/pic.car.prompt.txt) | 2026-10-28 | OpenAI built-in image-generation tool driven through `codex exec` (Codex CLI 0.165.0); model/version not exposed. Background removed locally with Pillow |
| bus (#325) | [Prompt](design/art-samples/prompts/pic.bus.prompt.txt) | 2026-10-28 | OpenAI built-in image-generation tool driven through `codex exec` (Codex CLI 0.165.0); model/version not exposed. Background removed locally with Pillow |
| airplane (#325) | [Prompt](design/art-samples/prompts/pic.airplane.prompt.txt) | 2026-10-28 | OpenAI built-in image-generation tool driven through `codex exec` (Codex CLI 0.165.0); model/version not exposed. Background removed locally with Pillow |
| rocket (#325) | [Prompt](design/art-samples/prompts/pic.rocket.prompt.txt) | 2026-10-28 | OpenAI built-in image-generation tool driven through `codex exec` (Codex CLI 0.165.0); model/version not exposed. Background removed locally with Pillow |
| bicycle (#325) | [Prompt](design/art-samples/prompts/pic.bicycle.prompt.txt) | 2026-10-28 | OpenAI built-in image-generation tool driven through `codex exec` (Codex CLI 0.165.0); model/version not exposed. Background removed locally with Pillow |
| train (#325) | [Prompt](design/art-samples/prompts/pic.train.prompt.txt) | 2026-10-28 | OpenAI built-in image-generation tool driven through `codex exec` (Codex CLI 0.165.0); model/version not exposed. Background removed locally with Pillow |
| sailboat (#325, reuses #323 sample as production) | [Prompt](design/art-samples/prompts/pic.sailboat.prompt.txt) | 2026-10-28 | Reused from the merged #323 sample (Muse built-in image generation; model/version not exposed); no new generation |

Notes for #325: the prompt files follow the #323 sample pattern (white background, "ONLY" single object) because the tool does not output transparency; the background and enclosed white were then removed locally and a thin cream outer edge was added to the 18 new pictures (the bicycle's is in its prompt). Orange and bicycle were regenerated once after the sheet review.
| guitar (#326) | [Prompt](design/art-samples/prompts/guitar.prompt.txt) | 2026-10-28 | OpenAI Images API (`/v1/images/generations`), model `gpt-image-1.5`, quality high, 1024×1024, text prompt only; white background removed locally (Pillow flood fill), cropped, fitted in 480px on a 600×600 transparent canvas |
| coffee (#326) | [Prompt](design/art-samples/prompts/coffee.prompt.txt) | 2026-10-28 | OpenAI Images API (`/v1/images/generations`), model `gpt-image-1.5`, quality high, 1024×1024, text prompt only; white background removed locally (Pillow flood fill), cropped, fitted in 480px on a 600×600 transparent canvas |
| star (#326) | [Prompt](design/art-samples/prompts/star.prompt.txt) | 2026-10-28 | OpenAI Images API (`/v1/images/generations`), model `gpt-image-1.5`, quality high, 1024×1024, text prompt only; white background removed locally (Pillow flood fill), cropped, fitted in 480px on a 600×600 transparent canvas |
| bee (#326) | [Prompt](design/art-samples/prompts/bee.prompt.txt) | 2026-10-28 | OpenAI Images API (`/v1/images/generations`), model `gpt-image-1.5`, quality high, 1024×1024, text prompt only; white background removed locally (Pillow flood fill), cropped, fitted in 480px on a 600×600 transparent canvas |
| cactus (#326) | [Prompt](design/art-samples/prompts/cactus.prompt.txt) | 2026-10-28 | OpenAI Images API (`/v1/images/generations`), model `gpt-image-1.5`, quality high, 1024×1024, text prompt only; white background removed locally (Pillow flood fill), cropped, fitted in 480px on a 600×600 transparent canvas |
| clock (#326) | [Prompt](design/art-samples/prompts/clock.prompt.txt) | 2026-10-28 | OpenAI Images API (`/v1/images/generations`), model `gpt-image-1.5`, quality high, 1024×1024, text prompt only; white background removed locally (Pillow flood fill), cropped, fitted in 480px on a 600×600 transparent canvas |
| house (#326) | [Prompt](design/art-samples/prompts/house.prompt.txt) | 2026-10-28 | OpenAI Images API (`/v1/images/generations`), model `gpt-image-1.5`, quality high, 1024×1024, text prompt only; white background removed locally (Pillow flood fill), cropped, fitted in 480px on a 600×600 transparent canvas |
| chair (#326) | [Prompt](design/art-samples/prompts/chair.prompt.txt) | 2026-10-28 | OpenAI Images API (`/v1/images/generations`), model `gpt-image-1.5`, quality high, 1024×1024, text prompt only; white background removed locally (Pillow flood fill), cropped, fitted in 480px on a 600×600 transparent canvas |
| umbrella (#326) (second round: first prompt gave a too-thin upright umbrella, rejected) | [Prompt](design/art-samples/prompts/umbrella.prompt.txt) | 2026-10-28 | OpenAI Images API (`/v1/images/generations`), model `gpt-image-1.5`, quality high, 1024×1024, text prompt only; white background removed locally (Pillow flood fill), cropped, fitted in 480px on a 600×600 transparent canvas |
| book (#326) (second round: first prompt drew an emblem on the cover, rejected) | [Prompt](design/art-samples/prompts/book.prompt.txt) | 2026-10-28 | OpenAI Images API (`/v1/images/generations`), model `gpt-image-1.5`, quality high, 1024×1024, text prompt only; white background removed locally (Pillow flood fill), cropped, fitted in 480px on a 600×600 transparent canvas |
| lamp (#326) | [Prompt](design/art-samples/prompts/lamp.prompt.txt) | 2026-10-28 | OpenAI Images API (`/v1/images/generations`), model `gpt-image-1.5`, quality high, 1024×1024, text prompt only; white background removed locally (Pillow flood fill), cropped, fitted in 480px on a 600×600 transparent canvas |
| sunflower (reused from #323 for #326, copied unchanged) | [Prompt](design/art-samples/prompts/sunflower.prompt.txt) | 2026-10-28 | Reused #323 sample; see that row |
| moon (reused from #323 for #326, copied unchanged) | [Prompt](design/art-samples/prompts/moon.prompt.txt) | 2026-10-28 | Reused #323 sample; see that row |
| key (reused from #323 for #326, copied unchanged) | [Prompt](design/art-samples/prompts/key.prompt.txt) | 2026-10-28 | Reused #323 sample; see that row |
