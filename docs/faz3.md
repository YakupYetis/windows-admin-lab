## Shared Folder & NTFS


![shares](../screenshots/shares.png)
![AGLDP](../screenshots/AGDLP.png)

belirtilen şekilde shares dosyası oluşturuldu ve AGDLP mantığıyla klasör yetkilendirmeleri yapıldı örnek HR kullanıcıları için AGDLP yapısı

|İsim|Türü| üyelik/yetki|
|---|---|---|
|Ali HR|User|G_HR_Users|
|Mehmet HR|User|G_HR_Users|
|G_HR_Users|Global Security Group|Local-HR|
|Local-HR|Local Security Group|NTFS Yetkilendirmeleri|

<br>

![HR](../screenshots/HR.png)
Yetkilendirme işlemlerinden sonra HR grubuna ait kullanıcılar görüldüğü üzere IT klasörüne erişim sağlayamıyor

Ortak klasörü için her departmana özel yönetici grupları oluşturuldu ve bu gruplara full control yetkisi verilirken diğer gruplara sadece lis ve read yetkisi verildi.


## Drive Mapping
![map1](../screenshots/drivemaps.png)
GPO editör üzerinden görüleceği gibi SRV01 üzerinden IT HR ve Muhasebe birimlerinin herbiri için bir harf atanmıştır ve aşağıda görüleceği üzere policy şu anda aktif durumdadır.
![map2](../screenshots/gpodrivemapping.png)

## File Audit Logs

![audit](../screenshots/eventviwr.png)
![audit2](../screenshots/eventviwrdlt.png)


## Backup & Restore

![Backup](../screenshots/Backup.png)
![Delete](../screenshots/OnemliDelete.png)
Yukarıda  önemli.txt dosyasının Wİndows Server Backup backup alımı ve Event Viewer üzerinden silinme logları görülmekte.
![Recovery](../screenshots/Recovery.png)
![Recovery2](../screenshots/recovereventviwr.png)
Bu noktada ise File recovery ekranı ve event viewer ile dosyanın geri getirilme ekranları görülmekte.