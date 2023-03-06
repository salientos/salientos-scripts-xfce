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

sha512sums=('2c1403b7e6445c56b4f030acbd0e9074050a4b00a4acc1300c2cc995c3dd8bd86225c9a17243d22cf9926af53d81e732892f0ede29c0c43c908b611a1d26948b'
            '71e9898f8d1a4b1e23f2eab4e3b2a0fe481d1d989b23b233efd0bdab398e67d35b4502cbac85c3caedf1f41315128082ac54f212de5f7901f19bacff8bd961e5')

package() {
	local bin=${pkgdir}/usr/bin
	
	install -Dm755 chrooted_post_install.sh 	${bin}/chrooted_post_install.sh
	install -Dm755 post_install.sh 				${bin}/post_install.sh
	
	chmod +x ${bin}/chrooted_post_install.sh
	chmod +x ${bin}/post_install.sh
}
