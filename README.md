#  GCDAsyncSocketDemo

使用GCDAsyncSocket进行局域网文件传输，可用于数据迁移。配套Android demo：https://github.com/Mamong/SocketDemo



三、传输阶段
传输时机：连接成功后，由客户端主动发起请求。

传输过程：
1.客户端发送JSON：{“cmd”:“REQ_FILE_INFO_LIST”,“timestamp”} 请求文件列表
2.服务端收到消息后，发送文件列表信息JSON：{“cmd”:“RSP_FILE_INFO_LIST”,“files”:[],“totalSize”,“timestamp”}。
3.客户端接收到文件列表信息后，先根据totalSize检查自身剩余磁盘空间是否足够，不足则提示。然后按顺序回传文件信息JSON：{“cmd”:“REQ_FILE”,“file”:{},“timestamp”}。
4.服务端接收到文件信息后，发送对应文件的数据。
5.客户端接收文件完成后，需要对文件进行md5 hash，跟文件列表中的checkSum进行比较，一致则下载下一个文件，不一致则重新完整下载一次该文件。仍然失败，则加入失败队列，下载下一个文件（本demo未实现重试功能）。传输完成后，提示有多少个会话传输未完成，是重新下载还是放弃。文件传输失败则导入导出失败，不再传输其他文件。

相关文件信息结构：
服务端下发文件信息：{“id”,“fileName”,“fileType”,“fileSize”,“checkSum”}，id可简单处理为序号，fileType区分文件类型，便于客户端进行不同处理，fileSize使客户端知道文件是否下载完毕, checkSum用于校验文件完整性。
客户端回传文件信息：{“id”,“acceptSize”}，acceptSize告诉服务端从文件某个位置开始传输，不传为0。

数据以LTV的格式进行编码：L是载荷数据的长度，4个字节；T是数据类型，4个字节，0表示是JSON数据，1表示文件数据；V是消息载荷。
注意点：注意大小端的处理
