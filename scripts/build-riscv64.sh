#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
kernel_release="${KERNELRELEASE:-$(uname -r)}"
kernel_build="${KERNEL_BUILD:-/lib/modules/${kernel_release}/build}"
output_dir="${OUTPUT_DIR:-${repo_root}/build/riscv64}"

if [[ "$(uname -m)" != "riscv64" ]]; then
  echo "This script is intended to run natively on riscv64; got $(uname -m)." >&2
  exit 2
fi

if [[ ! -d "${kernel_build}" ]]; then
  echo "Kernel build directory not found: ${kernel_build}" >&2
  echo "Set KERNEL_BUILD to the configured kernel headers/build tree." >&2
  exit 2
fi

mkdir -p "${output_dir}"

make -C "${repo_root}/XDMA/linux-kernel/xdma" \
  BUILDSYSTEM_DIR="${kernel_build}" \
  KBUILD_MODPOST_WARN=1 \
  all

make -C "${repo_root}/XDMA/linux-kernel/tools" clean all

cp "${repo_root}/XDMA/linux-kernel/xdma/xdma.ko" "${output_dir}/"
cp "${repo_root}/XDMA/linux-kernel/tools/"{dma_from_device,dma_to_device,performance,reg_rw,test_chrdev} "${output_dir}/"

modinfo "${output_dir}/xdma.ko" > "${output_dir}/xdma.modinfo.txt" || true
file "${output_dir}"/* | tee "${output_dir}/file.txt"
modinfo "${output_dir}/xdma.ko" | grep -E '^(name|vermagic|depends|alias):' || true
