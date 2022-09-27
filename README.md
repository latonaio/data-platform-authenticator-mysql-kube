# data-platfrom-authenticator-mysql-kube
data-platfrom-authenticator-mysql-kube は、Kubernetes 上で MariaDB(MySQL) の Pod を立ち上げ稼働させるための マイクロサービス です。    
本リポジトリには、必要なマニフェストファイルが入っています。  
また、本リポジトリには、MySQLの初期設定と、Pod立ち上げ後のテーブルの作成に関する手順が含まれています。  
AIONでは、MySQLは主に、エッジアプリケーションで発生した静的なデータを保持・維持するために用いられます。  

## 動作環境

* OS: Linux OS  

* CPU: ARM/AMD/Intel  

* Kubernetes  


## data-platfrom-authenticator-mysql-kube を用いたエッジコンピューティングアーキテクチャ  
data-platfrom-authenticator-mysql-kube は、下記の黄色い枠の部分のリソースです。  
![mysql_dataplatform](docs/dataplatform_architecture.drawio.png)  

## Kubernetes 上での MySQL の Pod 立ち上げ  
以下の手順でKubernetes上にMySQLのPodを立ち上げます。  

[1] 以下コマンドを実行してください    

```
$ kubectl apply -f service.yaml
```

[2] 以下コマンドでMySQLのPodが正常に起動している事を確認してください  

```
$ k get pod | grep mysql
```

## MySQL 立上げ・稼働 のための Kubernetes マニフェストファイル の設定
上記 MySQL の Pod 立ち上げ のための マニフェストファイル は`service.yaml`です。

* ポート: 3306   
* コンテナイメージ: mariadb:10.6   
* volumeのマウント場所 
	* **persistentVolume**:
		* コンテナ: /var/lib/mysql
		* hostOS: /mnt/mysql_data
	* **initdb**:   
		* コンテナ: /docker-entrypoint-initdb.d
		* hostOS: /mnt/mysql_init
	* **current-dir**:   
		* コンテナ: /src
		* hostOS: /home/latona/data-platform-authenticator-mysql-kube
* タイムゾーン: Asia/Tokyo   

current-dirのhostOSはセットアップ環境に合わせて変えること

## MySQLデータベース の作成 および アプリケーション の テーブル の作成    
MySQLデータベースを作成します。また、アプリケーションのテーブルを作成します。 

```
$ bash setup-mysql.sh
```
MySQLデータベース作成の該当箇所は`setup-mysql.sh`の以下の部分です

```
kubectl exec -it ${MYSQL_POD} -- bash -c "mysql -u${DB_USER_NAME} -p${DB_USER_PASSWORD} -e \"CREATE DATABASE IF NOT EXISTS DataPlatformAuthenticatorMySQLKube default character set utf8 ;\""
```

アプリケーションのテーブル作成の該当箇所は`setup-mysql.sh`の以下の部分です

```
kubectl exec -it ${MYSQL_POD} -- bash -c "mysql -u${DB_USER_NAME} -p${DB_USER_PASSWORD} -D DataPlatformAuthenticatorMySQLKube < /src/data-platform-authenticator-sql-business-user-data.sql"
```

`${MYSQL_POD}`、`${DB_USER_NAME}`および`${DB_USER_PASSWORD}`はセットアップ環境に合わせて変えること


## MariaDB について
エッジ環境はスペックの制限があるため、機能性とパフォーマンスのバランスに優れているMariaDB(MySQL)を採用しています。   
RDBMSにはSQLite、SQL ServerやPostgreSQLなどがあります。 

* SQLite: 軽量で手頃だが、大規模なシステムでは機能不十分  
* PostgreSQL: 高性能だが、処理コストが高い  

MariaDB(MySQL)はSQL ServerやPostgreSQLの中間に位置し、高速で実用性が高いため、LatonaおよびAIONではエッジ環境で採用されています。   

以下、MariaDBの特徴です。   

### MariaDB とは
MariaDBはMySQLから派生したもので、MySQLと高い互換性があります。   

《MySQLとMariaDBの違い》

|    |MariaDB|MySQL|   
|:---|:---|:---|    
|ライセンス|オープンソース(GPL)|オープンソース(プロプライエタリ・ライセンス)|   
|管理|コミュニティによる管理|Oracle社によるベンダー管理|   
|シェア|Linuxディストリビューションでの採用など急速に伸びている|非常に高い|   
|セキュリティ（暗号化機能）|暗号化の対象が多い|暗号化は限られている|   
|パフォーマンス|高い|MariaDBには劣る|   
|堅牢性|高い|普通|   
|クラスター構成|対応|非対応|   


### リレーショナル・データベース
MariaDB(MySQL)は、リレーショナルデータベースです。
リレーショナルデータベースとは、データベース(DB)におけるデータを扱う方法の1つで、主に2つの特徴があります。   

1. データは2次元(行×列)の表(テーブル)形式で表現   
2. 「キー」を利用して、複数の表を結合(リレーション)して利用可能   

データを2次元の表に分割し、また複数の表を様々な手法で結合して使うことで、複雑なデータを柔軟に扱うことができます。   

### 高い拡張性・柔軟性・速度
MariaDB(MySQL)の利点は以下の通りです。 

* システム規模が大きくなっても対応できる拡張性   
* さまざまなテーブルタイプのデータを統合できる柔軟性   
* 大規模なデータにも耐えうるような高速動作   
* データを保護するためのセキュリティ機能（データベースにアクセスするためのアクセス制限、盗み見防止のデータ暗号機能、Webサイトなどを安全に接続するためのセキュリティ技術など）   

### トランザクションとロールバック
トランザクションとはDBシステムで実行される処理のまとまり、または作業単位のことです。   
トランザクションを使うと複数のクエリをまとめて１つの処理として扱うことができます。   

* **処理の途中でエラーになって処理を取り消したいような場合**：「ロールバック; roll back」をすることで、そのトランザクションによる痕跡を消去してデータベースを一貫した状態（そのトランザクションを開始する前の状態）にリストアできます。   
* **あるトランザクションの全操作が完了した場合**：そのトランザクションはシステムによって「コミット; commit」され、DBに加えられた更新内容が恒久的なものとなります。コミットされたトランザクションがロールバックされることはありません。    

MariaDB(MySQL)では、トランザクション処理を行うことで、MariaDB(MySQL)のテーブルにデータを保存などをする際に、他のユーザーからのアクセスを出来ないようにテーブルをロックしています。

## MySQL Workbench
MySQL Workbenchとは、MySQLの公式サイトにてMySQL Serverと共に無料で配布されている、
データ・モデリング、SQL 開発、およびサーバー設定、ユーザー管理、バックアップなどの包括的な管理ツールのことです。
コマンドラインではなくビジュアル操作（GUI）に対応しています。
MySQL Workbench は Windows、Linux、Mac OS X で利用可能です。

* **データベース設計**：新規にER図が作成できるほか、既存のデータベースからER図を逆に生成することも可能です。   
* **データベース開発**：SQLのクエリ作成や実行だけでなく、最適化を直感的な操作で行えるビジュアル表示に対応しています。さらにSQLエディタにはカラーハイライト表示や自動補完機能のほか、SQLの実行履歴表示やSQLステートメントの再利用、オブジェクトブラウザにも対応しており、SQLエディタとしてもとても優秀な開発ツールです。   
* **データベース管理**：ヴィジュアルコンソールによってデータベースの可視性が高められており、MySQLの管理をより容易にする工夫が凝らされています。さらにビジュアル・パフォーマンス・ダッシュボードの実装により、パフォーマンス指標を一目で確認できます。   