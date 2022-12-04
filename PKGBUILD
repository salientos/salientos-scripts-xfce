#Maintainer: silent robot (d3signr@gmail.com)

pkgname=salientos-scripts-xfce
pkgver=1.0
pkgrel=0
pkgdesc='Salient OS Install Scripts'
url="https://github.com/salientos/"
arch=('any')
license=('GPL3')
makedepends=('git')
depends=()
conflicts=('salientos-scripts-kde')
provides=("${pkgname}")
options=(!strip !emptydirs)

source=('chrooted_post_install.sh'
		'post_install.sh')

sha512sums=('54073a6c46bb61586c4adf05e9aca9655a17632e298a579e5a9596c4f7c93c5c086ba8f7d8fc5c9561bc02fe0337b9eb9e90104ee620de44e81c8c2f0b743a69'
            '83956261269ee95b41d49f082a683e74324e668608159e014a6c33c26f4bd5672a0e6589e2ccaf1457b11a6d6aafe1ab2b6f327c013ce0f707ce74a7d9699891')

package() {
	local bin=${pkgdir}/usr/bin
	
	install -Dm755 chrooted_post_install.sh 	${bin}/chrooted_post_install.sh
	install -Dm755 post_install.sh 				${bin}/post_install.sh
}
