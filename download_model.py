import os, sys, glob, urllib.request

REPO_ID = "InternScience/Agents-A1-4B-Q4_K_M-GGUF"
FILENAME = "Agents-A1-4B-Q4_K_M.gguf"
DOWNLOAD_URL = f"https://huggingface.co/{REPO_ID}/resolve/main/{FILENAME}"

cache_base = os.path.expanduser("~/.cache/huggingface/hub/models--InternScience--Agents-A1-4B-Q4_K_M-GGUF")
snapshot_dir = os.path.join(cache_base, "snapshots", "default")
model_path = os.path.join(snapshot_dir, FILENAME)

# 1. Checar se ja existe no cache local
matches = glob.glob(os.path.join(cache_base, "**", "*.gguf"), recursive=True)
if not matches:
    matches = glob.glob(os.path.expanduser("~/.cache/huggingface/hub/**/d93c393a9bd5139a4b5cfe24d31ef553c5a497bfb8afec178a354ecbf508f062"), recursive=True)

if matches:
    print(matches[0])
    sys.exit(0)

# 2. Se nao existir, realizar o download do HuggingFace
os.makedirs(snapshot_dir, exist_ok=True)
print(f"📥 Baixando modelo de pesos do HuggingFace ({REPO_ID})...", file=sys.stderr)

def progress_hook(block_num, block_size, total_size):
    downloaded = block_num * block_size
    if total_size > 0:
        percent = (downloaded / total_size) * 100
        mb_down = downloaded / (1024 * 1024)
        mb_total = total_size / (1024 * 1024)
        print(f"\r Progress: {percent:.1f}% ({mb_down:.1f}/{mb_total:.1f} MB)", end="", file=sys.stderr)

try:
    urllib.request.urlretrieve(DOWNLOAD_URL, model_path, reporthook=progress_hook)
    print(f"\n✅ Download concluído com sucesso!", file=sys.stderr)
    print(model_path)
except Exception as e:
    print(f"\n❌ Erro no download: {e}", file=sys.stderr)
    sys.exit(1)
