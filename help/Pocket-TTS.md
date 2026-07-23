# Pocket TTS

This provider exposes every `.npy` and `.wav` voice installed in
`%APPDATA%\nvda\pocket_tts\voices` through STAR. It uses the ONNX engine from
the installed NVDA Pocket TTS add-on and the models already stored in NVDA's
Pocket TTS data directory.

## Setup

1. Install NVDA and the Pocket TTS NVDA add-on.
2. In NVDA, finish Pocket TTS's model setup and confirm that at least one voice
   appears in `%APPDATA%\nvda\pocket_tts\voices`.
3. Install STAR's normal requirements from the repository root.
4. Open the `provider\pocket_tts` directory and install this provider's extra
   requirements with `python -m pip install -r requirements.txt`.
5. In that directory, copy `pocket_tts.ini.example` to `pocket_tts.ini`. The
   example uses the local STAR server at `ws://localhost:7774`; replace it with
   another server only when you intentionally want to connect there.
6. Run `python pocket_tts.py` from the `provider\pocket_tts` directory.

The provider discovers voices each time it starts. Restart it after adding a new
`.npy` or `.wav` voice to Pocket TTS.

Python must have packages compiled for its own version. NVDA's bundled Python
libraries should not be copied into a separate STAR Python installation. The
provider reuses the add-on's engine source and models, while the requirements
below install compatible ONNX and numerical libraries for STAR's Python.

Pocket TTS currently does not expose rate or pitch controls, so those STAR
request fields are accepted but ignored.
