ip: bir networke bağlı cihazlara atanan numerik kimlik bilgisi cihazları ayırt etmeyi ve birbirleriyle iletişim kurmalarını sağlar

subnet mask: ip adresinin hangi kısmının bağlı olduğu ağ adresini hangi kısmının hostu gösterdiğini ayıran 32 bitlik sayı dizisi örneğin en yaygın olan 255.255.255.0 subnet maski üzerinden anlatacak olursak ip adresinin ilk 3 bloğu sabit sayı değerleri olmak zorundayken 4. blok 0 ve 255 arasındaki herhangi bir değer olabilir

CIDR: eski ip sınıflandırma sisteminin katı kuurallarını esneten ve ağları ihtiyaca göre subnetlere bölmemizi sağlayan modern gösterim biçimidir. kendi lab ortamım üzerinden devam edecek olursak oluşturduğum 10.30.0.x/24 ip bloğunun sonundaki /24 ilk 24 bitin ağ kimliği için ayrılmış ve kalan 8 bitinde host için ayrılmış olduğunu gösterir

Default gateway: bir bilgisayarım local networkten global ağa bağlanırken kullandığı adres genellikle modem yada router adresidir

dns: arama yaparken ip adreslerinden oluşan domain adresini daha ulaşılabilir olması için sözel ifadelere çevirir (örneğin 8.8.8.8/google.com)

DHCP: ağdaki cihazlara ip adresi subnet mask ve default gateway gibi bilgileri otomatik dağıtan protokol

NAT: private networklerdeki cihazların public internete tek bir ip adresiyle bağlanmasını sağlayan mekanizma ev ve işyerlerindeki binlerce cihazın aynı ip ile dış dünyaya bağlanmasını sağladığı için ip adreslerinde önemli bir tasarruf sağlar

MAC adresi: internet ağ kartının üretici tarafından kalıcı olarak atanan benzersiz fiziksel adresidir

TCP: connection oriented odaklı bir veri iletim protokolü veri gönderilmeden önce taraflar arasında handshake yapılır ve giden paketlerin eksiksiz ulaşıp ulaşmadığı kontrol edilir eksik varsa tekrar istenir

UDP: connectionless bir veri iletim protokolüdür paketlerin karşı tarafa varıp varmadığını kontrol etmez veya kayıpları tekrar isteyip vakit kaybetmez anlık hızın önemli olduğu canlı yayın ve sesli görüşme gibi alanlarda tercih edilir

port: bilgisayara gelen ağ trafiğinin o cihaz üzerinde hangi uygulama ve servise iletileceğini belirleyen sanal kapılar

private ip: ev okul laboratuvar gibi kapalı yerel ağlarda kullanılan ip adresleri (örneğin bu labdaki makinelerin ip adresleri 10.30.0.x şeklinde class A ip adresleridir) doğrudan dış internete yönlendirilemezler.

public ip: küresel internette iss tarafından atanan ip adresidir web siteleri veya dış servisler bu atanan ip adresini görür

static ip: bir cihaza kullanıcı veya yönetici tarafından elle verilen ve kendiliğinden değişmeyen ip adresleridir genellikle sunucularda ve lab bileşenlerinde tercih edilir örneğin benim oluşturduğum laboratuvarda IP adreslerinin hepsini elle atadığım için bütün IP adresleri statiktir

dynamic ip: bir DHCP sunucusu tarafından geçici olarak atanan ve her yeniden bağlantıda değişenilen ip adresidir ev internetinde her başlatmada cihaz ip adreslerinin sürekli farklı görünmesinin sebebide budur