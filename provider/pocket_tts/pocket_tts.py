"""STAR provider for voices installed by the NVDA Pocket TTS add-on."""

import asyncio
import io
import os
import sys
import threading
import wave
from pathlib import Path


APPDATA = Path(os.environ.get("APPDATA", Path.home() / "AppData" / "Roaming"))
NVDA_DIR = APPDATA / "nvda"
POCKET_DATA_DIR = NVDA_DIR / "pocket_tts"
POCKET_ADDON_DIR = NVDA_DIR / "addons" / "Pocket-TTS"
POCKET_ENGINE_DIR = POCKET_ADDON_DIR / "synthDrivers" / "pocket_tts_onnx"

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
sys.path.insert(0, str(POCKET_ENGINE_DIR))

from provider import star_provider
from pocket_tts_onnx import PocketTTSOnnx


class pocket_tts_provider(star_provider):
	"""Expose every Pocket TTS .npy/.wav voice to a STAR coagulator."""

	def __init__(self):
		self._engine = None
		self._engine_lock = threading.Lock()
		super().__init__(
			"pocket_tts",
			run_immedietly=False,
			synthesis_audio_extension="wav",
		)
		self.config.setdefault("concurrent_requests", "1")
		self.run()

	@property
	def voices_dir(self):
		return POCKET_DATA_DIR / "voices"

	def get_voices(self):
		voices = {}
		seen = set()
		if not self.voices_dir.is_dir():
			raise FileNotFoundError(f"Pocket TTS voices directory not found: {self.voices_dir}")
		for extension in (".npy", ".wav"):
			for path in sorted(self.voices_dir.glob(f"*{extension}"), key=lambda p: p.name.casefold()):
				if path.stem.casefold() in seen:
					continue
				seen.add(path.stem.casefold())
				name = f"Pocket TTS {path.stem.replace('_', ' ').title()}"
				voices[name] = {"full_name": str(path)}
		return voices

	def _get_engine(self):
		if self._engine is None:
			models_dir = POCKET_DATA_DIR / "onnx"
			tokenizer_path = POCKET_DATA_DIR / "tokenizer.model"
			if not models_dir.is_dir() or not tokenizer_path.is_file():
				raise FileNotFoundError(f"Pocket TTS models were not found under {POCKET_DATA_DIR}")
			self._engine = PocketTTSOnnx(
				models_dir=str(models_dir),
				tokenizer_path=str(tokenizer_path),
				precision="int8",
				device="cpu",
				lsd_steps=1,
				eos_threshold=-2.0,
			)
		return self._engine

	@staticmethod
	def _to_wav(audio):
		import numpy as np
		pcm = (np.clip(audio, -1.0, 1.0) * 32767).astype(np.int16)
		output = io.BytesIO()
		with wave.open(output, "wb") as wav:
			wav.setnchannels(1)
			wav.setsampwidth(2)
			wav.setframerate(PocketTTSOnnx.SAMPLE_RATE)
			wav.writeframes(pcm.tobytes())
		return output.getvalue()

	def _synthesize_blocking(self, voice, text):
		with self._engine_lock:
			audio = self._get_engine().generate(text=text, voice=voice)
			return self._to_wav(audio)

	async def synthesize(self, voice, text, rate=None, pitch=None):
		try:
			return await asyncio.to_thread(self._synthesize_blocking, voice, text)
		except Exception as error:
			return f"Pocket TTS synthesis failed: {error}"


if __name__ == "__main__":
	pocket_tts_provider()
