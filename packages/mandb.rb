require 'package'

class Mandb < Package
  description 'mandb is used to initialise or manually update index database caches that are usually maintained by man.'
  homepage 'http://savannah.nongnu.org/projects/man-db'
  version '2.7.6.1-1'
  source_url 'http://download.savannah.gnu.org/releases/man-db/man-db-2.7.6.1.tar.xz'
  source_sha256 '08edbc52f24aca3eebac429b5444efd48b9b90b9b84ca0ed5507e5c13ed10f3f'

  depends_on 'less'
  depends_on 'libpipeline'
  depends_on 'gdbm'
  depends_on 'groff'
  depends_on 'pkgconfig'
  depends_on 'readline'
  depends_on 'zlibpkg'

  def self.build
    system './configure',
      '--with-systemdtmpfilesdir=/usr/local/lib/tmpfiles.d',  # we can't write to /usr/lib/tmpfiles.d
      '--disable-cache-owner',                                # we can't create the user 'man'
      '--with-pager=/usr/local/bin/less'                      # the pager is not at the default location
    system 'make'
  end

  def self.install
    system "mkdir -p #{CREW_DEST_DIR}/usr/local/cache/man"
    system "sed -i 's,/var/cache/man,/usr/local/cache/man,g' include/manconfig.h.in"
    system "sed -i 's,/var/cache/man,/usr/local/cache/man,g' src/manp.c"
    system "sed -i 's,/var/cache/man,/usr/local/cache/man,g' src/tests/mandb-7"
    system "sed -i 's,/var/cache/man,/usr/local/cache/man,g' src/man_db.conf.in"
    system "sed -i 's,/var/cache/man,/usr/local/cache/man,g' init/systemd/man-db.conf"
    system "sed -i 's,/var/cache/man,/usr/local/cache/man,g' manual/db.me"
    system "sed -i 's,/var/cache/man,/usr/local/cache/man,g' manual/files.me"
    system "sed -i 's,/var/cache/man,/usr/local/cache/man,g' man/man1/whatis.man1"
    system "sed -i 's,/var/cache/man,/usr/local/cache/man,g' man/man1/apropos.man1"
    system "sed -i 's,/var/cache/man,/usr/local/cache/man,g' man/man1/man.man1"
    system "sed -i 's,/var/cache/man,/usr/local/cache/man,g' man/man8/accessdb.man8"
    system "sed -i 's,/var/cache/man,/usr/local/cache/man,g' man/man8/mandb.man8"
    system "sed -i 's,/usr/share/man,/usr/local/share/man,g' tools/chconfig"
    system "sed -i 's,/var/cache/man,/usr/local/cache/man,g' tools/chconfig"
    system "make", "DESTDIR=#{CREW_DEST_DIR}", "install"
    puts ""
    puts "You will have to change the default PAGER environment variable to be able to use mandb:".lightblue
    puts "echo \"export PAGER=/usr/local/bin/less\" >> ~/.bashrc && . ~/.bashrc".lightblue
    puts ""
    puts "You will also have to set the MANPATH environment variable:".lightblue
    puts "echo \"export MANPATH=/usr/local/man:$MANPATH\" >> ~/.bashrc && . ~/.bashrc".lightblue
    puts ""
    puts "To create the man databases and get apropos working, type 'mandb -c'.".lightblue
    puts ""
  end
end
