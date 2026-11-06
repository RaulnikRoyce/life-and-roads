#!/usr/bin/env bash
set -euo pipefail

raiz=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)
mkdir -p "$raiz/app/build"
fixture=$(mktemp -d "$raiz/app/build/ci-ndk.XXXXXX")
fixture=$(cd "$fixture" && pwd -P)
case "$fixture" in
  "$raiz/app/build/ci-ndk."*) ;;
  *) echo 'Diretório de teste fora do projeto.'; exit 1 ;;
esac
limpar() {
  case "$fixture" in
    "$raiz/app/build/ci-ndk."*) rm -rf -- "$fixture" ;;
    *) return 1 ;;
  esac
}
trap limpar EXIT

export FLUTTER_ROOT="$fixture/flutter"
export ANDROID_SDK_ROOT="$fixture/sdk"
export GITHUB_OUTPUT="$fixture/outputs"
export FAKE_CALLS="$fixture/calls"
export FAKE_NDK_MODE=retry
extension="$FLUTTER_ROOT/packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt"
mkdir -p "$(dirname "$extension")" "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin"
printf '    val ndkVersion: String = "28.2.13676358"\n' > "$extension"
echo 0 > "$FAKE_CALLS"
cat > "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
n=$(cat "$FAKE_CALLS")
n=$((n + 1))
echo "$n" > "$FAKE_CALLS"
ndk="$ANDROID_SDK_ROOT/ndk/28.2.13676358"
[[ "$2" == --install && "$3" == 'ndk;28.2.13676358' ]]
[[ ! -f "$ANDROID_SDK_ROOT/.temp/corrompido" ]]
if [[ "$FAKE_NDK_MODE" == falha ]]; then exit 1; fi
if [[ "$FAKE_NDK_MODE" == incompleto ]]; then exit 0; fi
mkdir -p "$ndk/toolchains/llvm/prebuilt/linux-x86_64/bin"
if [[ "$FAKE_NDK_MODE" == retry && "$n" == 1 ]]; then
  mkdir -p "$ANDROID_SDK_ROOT/.temp"
  touch "$ANDROID_SDK_ROOT/.temp/corrompido"
  echo 'Pkg.Revision = incompleto' > "$ndk/source.properties"
  exit 1
fi
echo 'Pkg.Revision = 28.2.13676358' > "$ndk/source.properties"
printf '#!/usr/bin/env bash\nexit 0\n' > "$ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/clang"
chmod +x "$ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/clang"
STUB
chmod +x "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager"
script="$raiz/.github/scripts/preparar-ndk.sh"

bash "$script" resolver
grep -qx 'version=28.2.13676358' "$GITHUB_OUTPUT"
[[ $(cat "$FAKE_CALLS") == 0 ]]
echo 'OK: resolução acompanha a versão do Flutter sem instalar.'
bash "$script"
[[ $(cat "$FAKE_CALLS") == 2 ]]
echo 'OK: instalação recupera arquivo corrompido e limpa temporários.'
bash "$script"
[[ $(cat "$FAKE_CALLS") == 2 ]]
echo 'OK: cache válido evita nova instalação.'

export FAKE_NDK_MODE=valido
echo 0 > "$FAKE_CALLS"
echo 'Pkg.Revision = 28x2x13676358' > "$ANDROID_SDK_ROOT/ndk/28.2.13676358/source.properties"
bash "$script"
[[ $(cat "$FAKE_CALLS") == 1 ]]
echo 'OK: revisão incorreta não passa pela validação.'

for modo in incompleto falha; do
  export FAKE_NDK_MODE="$modo"
  echo 0 > "$FAKE_CALLS"
  rm -f -- "$ANDROID_SDK_ROOT/ndk/28.2.13676358/source.properties"
  if bash "$script"; then echo 'Instalação inválida foi aceita.'; exit 1; fi
  [[ $(cat "$FAKE_CALLS") == 3 ]]
done
echo 'OK: falha persistente e sucesso sem arquivos param após três tentativas.'

printf '    val ndkVersion: String = "../../indevido"\n' > "$extension"
touch "$fixture/preservar"
if bash "$script"; then echo 'Versão inválida foi aceita.'; exit 1; fi
[[ -f "$fixture/preservar" && $(cat "$FAKE_CALLS") == 3 ]]
echo 'OK: versão inválida não dispara instalação ou limpeza.'
echo 'Todos os cenários de preparo do NDK passaram.'
