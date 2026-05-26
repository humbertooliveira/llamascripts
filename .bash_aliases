alias qwen='~/llamascripts/mtp-qwen3.6-27B.sh'
alias qwen35='~/llamascripts/mtp-qwen3.6-35B.sh'
# alias llamaupdate='sudo systemctl stop llamaserver.service && ~/llamascripts/update.sh && sudo systemctl start llamaserver.service'

hf-download() {
    if [ $# -eq 0 ]; then
        echo "Error: No URLs provided."
        echo "Usage: hf-download \"url1\" \"url2\" ... \"urlN\""
        return 1
    fi

    echo "Starting download of $# files..."
    
    for url in "$@"; do
        echo "-----------------------------------------------"
        echo "Downloading: $url"
        echo "-----------------------------------------------"
        
        # -L: Follow redirects
        # -O: Keep filename (ignores query strings like ?download=true)
        # -C -: Resume automatically from last byte
        curl -H "Authorization: Bearer $HF_TOKEN" -L -O -C - "$url"
    done
    
    echo "All downloads complete!"
}

gitgraph()
{
  # Default to current directory if no path is provided
  local repo_path="${1:-.}"

  # Verify the path is a valid git repository
  if ! git -C "$repo_path" rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Error: '$repo_path' is not a git repository." >&2
    return 1
  fi

  # Get the active branch name dynamically
  local current_branch=$(git -C "$repo_path" rev-parse --abbrev-ref HEAD)
  
  git -C "$repo_path" log --graph --left-right --pretty=format:"%C(auto)%m%h %ad:%d %s" --date=format:"%Y-%m-%d %H:%M" "origin/$current_branch" "$current_branch~40...$current_branch"
}

llamabuild()
{
  # 1. Define the installation directory
  local INSTALL_DIR="${1:-$HOME/llamacpp}"
  local BUILD_DIR="$INSTALL_DIR/build"

  sudo systemctl stop llamaserver.service

  # 5. Build with CUDA
  echo "🧹 Cleaning previous build..."
  rm -rf "$BUILD_DIR"
  mkdir -p "$BUILD_DIR"  

  echo "🛠️ Configuring build with CUDA..."

  export PATH=/usr/local/cuda-13.0/bin${PATH:+:${PATH}}
  export LD_LIBRARY_PATH=/usr/local/cuda-13.0/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
  
  cd $INSTALL_DIR
  
  cmake -B "$BUILD_DIR" \
    -DGGML_CUDA=ON \
    -DGGML_CUDA_F16=ON \
    -DCMAKE_CUDA_ARCHITECTURES=120 \
    -DGGML_NATIVE=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER=gcc-13 \
    -DCMAKE_CXX_COMPILER=g++-13 \
    -DCMAKE_CUDA_HOST_COMPILER=/usr/bin/gcc-13 \
    -DCMAKE_CUDA_FLAGS="-allow-unsupported-compiler" \
    
  echo "🏗️ Compiling..."
  time cmake --build "$BUILD_DIR" --config Release -j $(nproc);  

  cd - &>/dev/null

  sudo systemctl start llamaserver.service

  echo "--- ✅ Success! ---" 
}
