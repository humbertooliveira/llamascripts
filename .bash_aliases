alias qwen='~/llamascripts/mtp-qwen3.6-27B.sh'
alias qwen35='~/llamascripts/mtp-qwen3.6-35B.sh'
alias llamaupdate='sudo systemctl stop qwen3.6-35B.service && ~/llamascripts/update.sh && sudo systemctl start qwen3.6-35B.service'


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
        curl -L -O -C - "$url"
    done
    
    echo "All downloads complete!"
}

build-llama()
{
  # 1. Define the installation directory
  INSTALL_DIR="$HOME/llamacpp"
  BUILD_DIR="$INSTALL_DIR/build"

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

  echo "--- ✅ Success! ---" 
}