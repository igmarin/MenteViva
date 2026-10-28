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

| Slug | Prompt | Date | Tool / model / version |
|---|---|---|---|
| dog (sample, #323) | [Prompt](design/art-samples/prompts/dog.prompt.txt) | 2026-10-28 | Muse built-in image generation (`muse.image_generation`); model/version not exposed |
| apple (sample, #323; revised 2026-10-28 to match approved sheet) | [Prompt](design/art-samples/prompts/apple.prompt.txt) | 2026-10-28 | Muse built-in image generation (`muse.image_generation`); model/version not exposed |
| teapot (sample, #323) | [Prompt](design/art-samples/prompts/teapot.prompt.txt) | 2026-10-28 | Muse built-in image generation (`muse.image_generation`); model/version not exposed |
| sunflower (sample, #323) | [Prompt](design/art-samples/prompts/sunflower.prompt.txt) | 2026-10-28 | Muse built-in image generation (`muse.image_generation`); model/version not exposed |
| key (sample, #323) | [Prompt](design/art-samples/prompts/key.prompt.txt) | 2026-10-28 | Muse built-in image generation (`muse.image_generation`); model/version not exposed |
| sailboat (sample, #323) | [Prompt](design/art-samples/prompts/sailboat.prompt.txt) | 2026-10-28 | Muse built-in image generation (`muse.image_generation`); model/version not exposed |
| violin (sample, #323) | [Prompt](design/art-samples/prompts/violin.prompt.txt) | 2026-10-28 | Muse built-in image generation (`muse.image_generation`); model/version not exposed |
| moon (sample, #323; revised 2026-10-28 to match approved sheet) | [Prompt](design/art-samples/prompts/moon.prompt.txt) | 2026-10-28 | Muse built-in image generation (`muse.image_generation`); model/version not exposed |
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
