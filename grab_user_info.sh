cd users/;
for dir in */; do
	#User: zhengyinliu
	#Primary Investigator Name: Zhengyin Liu
	#Primary Investigator Email: liuzhy@pumch.cn

	if [[ -e "$dir/info.txt" ]]; then
		user_=$(head -n 1  "$dir/info.txt");
		userName_=$(head -n 2  "$dir/info.txt" | tail -n 1);
		email_=$(head -n 3  "$dir/info.txt" | tail -n 1);

		user=$(echo $user_ | awk -F': ' '{print $2}');
		userName=$(echo $userName_ | awk -F': ' '{print $2}');
		email=$(echo $email_ | awk -F': ' '{print $2}');
		echo -e "$user\t'$userName'\t$email";
	fi;
done
cd ../;
