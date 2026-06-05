#!/bin/bash
# Shared SDK runner — sourced by each tutorial's *-sdk.sh script.
set -eo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
LANG="${1:-}"
usage() {
    echo "Usage: $(basename "${BASH_SOURCE[1]}") <language>"
    echo "  python|py, javascript|js, java, go, ruby|rb, dotnet|cs, rust|rs, kotlin|kt, swift, php, cpp"
    echo ""
    echo "Available:"
    for d in "$SCRIPT_DIR"/*/; do [ -d "$d" ] && basename "$d" | grep -qvE '^\.' && echo "  $(basename "$d")"; done
    exit 1
}
[ -z "$LANG" ] && usage
case "$LANG" in
    python|py) DIR="python" ;; javascript|js|node) DIR="javascript" ;; java) DIR="java" ;;
    go|golang) DIR="go" ;; ruby|rb) DIR="ruby" ;; dotnet|csharp|cs) DIR="dotnet" ;;
    rust|rs) DIR="rust" ;; kotlin|kt) DIR="kotlin" ;; swift) DIR="swift" ;;
    php) DIR="php" ;; cpp|c++) DIR="cpp" ;; *) echo "Unknown: $LANG"; usage ;;
esac
LANG_DIR="$SCRIPT_DIR/$DIR"
[ ! -d "$LANG_DIR" ] && echo "No $DIR example for this tutorial." && usage
check_cmd() { command -v "$1" > /dev/null 2>&1 || { echo "Required: $1 not installed. Install: $2"; exit 1; }; }
case "$DIR" in
    python) check_cmd python3 "https://python.org/downloads/"; cd "$LANG_DIR"
        [ ! -d ".venv" ] && python3 -m venv .venv; source .venv/bin/activate; pip install -q -r requirements.txt
        echo "$ python3 scenario_getting_started.py"; echo ""; python3 scenario_getting_started.py ;;
    javascript) check_cmd node "https://nodejs.org/"; cd "$LANG_DIR"
        [ ! -d "node_modules" ] && npm install --quiet
        echo "$ node scenarios/getting-started.js"; echo ""; node scenarios/getting-started.js ;;
    java) check_cmd mvn "https://maven.apache.org/install.html"; cd "$LANG_DIR"
        echo "$ mvn -q compile exec:java"; mvn -q compile exec:java 2>&1 ;;
    go) check_cmd go "https://go.dev/dl/"; cd "$LANG_DIR"
        echo "$ go run scenarios/getting_started.go"; echo ""; go run scenarios/getting_started.go ;;
    ruby) check_cmd ruby "https://ruby-lang.org/"; cd "$LANG_DIR"
        [ ! -f "Gemfile.lock" ] && bundle install --quiet
        echo "$ ruby scenario_getting_started.rb"; echo ""; ruby scenario_getting_started.rb ;;
    dotnet) check_cmd dotnet "https://dotnet.microsoft.com/download"; cd "$LANG_DIR"
        echo "$ dotnet run"; echo ""; dotnet run ;;
    rust) check_cmd cargo "https://rustup.rs/"; cd "$LANG_DIR"
        echo "$ cargo run --bin scenario"; echo ""; cargo run --bin scenario ;;
    kotlin) check_cmd java "https://aws.amazon.com/corretto/"; cd "$LANG_DIR"
        echo "$ ./gradlew run"; chmod +x gradlew 2>/dev/null; ./gradlew run --quiet ;;
    swift) check_cmd swift "https://swift.org/download/"; cd "$LANG_DIR"
        echo "$ swift run"; echo ""; swift run ;;
    php) check_cmd php "https://php.net/downloads"; cd "$LANG_DIR"
        [ ! -d "vendor" ] && composer install --quiet
        echo "$ php GettingStartedScenario.php"; echo ""; php GettingStartedScenario.php ;;
    cpp) check_cmd cmake "https://cmake.org/download/"; cd "$LANG_DIR"
        mkdir -p build && cd build; echo "$ cmake .. && make && ./scenario"
        cmake .. -DCMAKE_BUILD_TYPE=Release > /dev/null 2>&1; make -j > /dev/null 2>&1 && ./scenario ;;
esac
