# 打开输出文件
exec 6>ok_ip.txt
exec 7>no_ip.txt

for i in $(cat ip.list); do
    # 检查是否能 ping 通机器
    if ping -c1 -s1 -w1 "$i" &>/dev/null; then
        # 成功则输出到 ok_ip.txt
        echo "$i" >&6
    else
        # 失败则输出到 no_ip.txt
        echo "$i" >&7
    fi
done

echo -e "*********************************$(date)********************************************" >>no_ip.txt
echo "现在ping不通的IP如下:"
cat no_ip.txt 
# 关闭输出文件
exec 6>&-
exec 7>&-
