#!/usr/bin/env bash
set -euo pipefail

extension="${FLUTTER_ROOT:?FLUTTER_ROOT ausente}/packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt"
ndk_version=$(awk '/^[[:space:]]*val ndkVersion:[[:space:]]*String[[:space:]]*=/ { gsub(/[";\r]/, ""); print $NF; exit }' "$extension")
if [[ ! "$ndk_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo '::error::Não foi possível identificar o NDK exigido pelo Flutter.'
  exit 1
fi
sdk_configurado="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}"
if [[ -z "$sdk_configurado" || ! -d "$sdk_configurado" ]]; then
  echo '::error::SDK Android ausente.'
  exit 1
fi
sdk_root=$(cd "$sdk_configurado" && pwd -P)
if [[ "$sdk_root" == / ]]; then
  echo '::error::Raiz do SDK Android inválida.'
  exit 1
fi
ndk_dir="$sdk_root/ndk/$ndk_version"

if [[ "${1:-instalar}" == resolver ]]; then
  printf 'version=%s\npath=%s\nsdk_root=%s\n' "$ndk_version" "$ndk_dir" "$sdk_root" >> "${GITHUB_OUTPUT:?GITHUB_OUTPUT ausente}"
  exit 0
fi

ndk_valido() {
  [[ -f "$ndk_dir/source.properties" ]] &&
    awk -F= -v versao="$ndk_version" '$1 ~ /^Pkg[.]Revision[[:space:]]*$/ { gsub(/[[:space:]]/, "", $2); if ($2 == versao) ok = 1 } END { exit !ok }' "$ndk_dir/source.properties" &&
    [[ -x "$ndk_dir/toolchains/llvm/prebuilt/linux-x86_64/bin/clang" ]]
}
if ndk_valido; then
  echo "NDK $ndk_version pronto para uso."
  exit 0
fi

sdkmanager="$sdk_root/cmdline-tools/latest/bin/sdkmanager"
if [[ ! -x "$sdkmanager" ]]; then
  echo '::error::sdkmanager não encontrado no SDK Android do runner.'
  exit 1
fi
for tentativa in 1 2 3; do
  # Apenas o pacote incompleto e os temporários do SDK deste job. A versão
  # contém somente dígitos e pontos; os alvos ficam sob a raiz física do SDK.
  for alvo in "$ndk_dir" "$sdk_root/.temp"; do
    case "$alvo" in
      "$sdk_root/ndk/$ndk_version"|"$sdk_root/.temp") rm -rf -- "$alvo" ;;
      *) echo '::error::Caminho de limpeza inválido.'; exit 1 ;;
    esac
  done
  echo "Instalando NDK $ndk_version, tentativa $tentativa de 3."
  if "$sdkmanager" --sdk_root="$sdk_root" --install "ndk;$ndk_version" && ndk_valido; then
    echo "NDK $ndk_version instalado e validado."
    exit 0
  fi
  if [[ "$tentativa" -lt 3 ]]; then
    sleep "$((tentativa * 5))"
  fi
done
echo '::error::Não foi possível preparar um NDK válido após três tentativas.'
exit 1
