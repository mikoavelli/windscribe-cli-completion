# Maintainer: mikoavelli <311810261+mikoavelli@users.noreply.github.com>

pkgname=windscribe-cli-bash-completion
pkgver=0.1.0
pkgrel=1
pkgdesc="Bash completion for windscribe-cli, the Windscribe VPN command line client"
arch=('any')
url="https://github.com/mikoavelli/windscribe-completion"
license=('MIT')
depends=('bash-completion')
optdepends=('windscribe-cli: the client this completes')
options=('!strip' '!debug')
source=("windscribe-cli.bash"
        "LICENSE")
sha256sums=('ac8d69e06145341faa2769b777b11be9f389c441915fd0c1a5eda9cc5ade1425'
            '41963884d41d04b72da2e5d81e7568f31cb59c0743d9e2e12adb353b698003fe')

package() {
    install -Dm644 "$srcdir/windscribe-cli.bash" \
        "$pkgdir/usr/share/bash-completion/completions/windscribe-cli"
    install -Dm644 "$srcdir/LICENSE" \
        "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
}

# After editing completions/windscribe-cli.bash, refresh the checksum with:
#   updpkgsums
