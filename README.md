# koolshare-aliddns multi domain edition

koolshare 梅林固件software center使用的aliddns插件.

因一时兴起买了个万网便宜域名,使用时发现没有多域名解析，域名得不到充分利用.

所以看了看代码临时增加多域名解析功能.

使用方法如下：

下载aliddns.tar.gz

打开koolshare software center页面

点击离线安装，选取aliddns.tar.gz安装即可

安装后暂时不可升级

我习惯于不在主页显示aliddns设置的域名，这样可以使用自己域名的同时使用asus的ddns.

两套域名解析可以同时共存.

页面显示更新成功后请自己看下自己的A记录是否发生了变化


关于代码实现
原来是这个样子的:

#support multi ip

array_current_ip=(1 2 3 4 5)

#support @ record nslookup

for i in $( seq 1 5 )
do
    tmp_name=aliddns_name$i
    tmp_domain=aliddns_domain$i

    eval tmp_name=\${$tmp_name}
    eval tmp_domain=\${$tmp_domain}

    if [ "$tmp_name" = "@" ]
    then
        array_current_ip[$i]=`nslookup $tmp_domain $aliddns_dns 2>&1`
    else
        array_current_ip[$i]=`nslookup $tmp_name.$tmp_domain $aliddns_dns 2>&1`
    fi
done

然而这种实现只能使用标准的bash.梅林自带只有sh.用ipkg安装bash比较麻烦...

所以使用了现在丑陋的实现...凑合用...

