# MongoDB 多文档事务

MongoDB 虽然已经在 4.2 开始全面支持了多文档事务，基本上可以到达和关系型数据库一样的效果，但并不代表大家应该毫无节制地使用它。相反，**对事务的使用原则应该是：能不用尽量不用**。为什么？因为**事务意味着：锁，节点协调，额外开销，性能影响**。

核心的场景下可以少量使用事务，大部分场景下通过合理地设计文档模型，可以规避绝大部分使用事务的必要性。

## 一. MongoDB ACID 多文档事务支持

| 事务属性           | 支持程度                                                     | 说明                                                         |
| :----------------- | :----------------------------------------------------------- | :----------------------------------------------------------- |
| Atomocity 原子性   | 单表单文档：1.x 就支持；复制集多表多行：4.0；复制集 分片集群多表多行：4.2 | 单表单文档：指一个文档有多个字段，在一次更新多个字段时，要么看到这些字段都被更新，要么看到都没更新，不会看到一些字段更新了另一些字段没更新的场景。  多行多文档多表：比如下单流程涉及订单表、库存表、账户表，或者一次行更新某张表的多行数据，就是需要多文档的支持 |
| Consistency 一致性 | writeConcern, readConcern (3.2)                              |                                                              |
| Isolation 隔离性   | readConcern (3.2)                                            | 默认情况下是有**脏读**发生，但可以通过 `readConcern majority` 很容易实现多节点提交读 |
| Durability 持久性  | Journal and Replication                                      | Journal 是先把数据先到日志文件再提交到数据文件，这能保证宕机的时候可以从日志文件中恢复。 |

## 二. MongoDB 事务的隔离级别

事务的隔离性指：在事务内的操作默认在事务外是看不到的，必须要同一事务内才能互相看得见。

隔离性：

- 事务完成前，事务外的操作对该事务所做的修改不可访问
- 如果事务内使用 `{readConcern: “snapshot”}`，则可以达到可重复读 `Repeatable Read`

## 三. 事务实验

### 3.1 读隔离

- 以下操作在同一个命令行窗口完成。

```javascript
rs0:PRIMARY> db.tx.insertMany([{ x: 1 }, { x: 2 }]);
{
        "acknowledged" : true,
        "insertedIds" : [
                ObjectId("6385e173e4c725a1336fff4d"),
                ObjectId("6385e173e4c725a1336fff4e")
        ]
}
```

- 验证插入成功：

```javascript
rs0:PRIMARY> db.tx.find()
{ "_id" : ObjectId("6385e173e4c725a1336fff4d"), "x" : 1 }
{ "_id" : ObjectId("6385e173e4c725a1336fff4e"), "x" : 2 }
```

- 启动 session，开启事务:

```javascript
rs0:PRIMARY> var session = db.getMongo().startSession();
rs0:PRIMARY> session.startTransaction();
```

- 获取表名:

```javascript
rs0:PRIMARY> var coll = session.getDatabase('test').getCollection("tx");
```

- 做更新操作，并查询验证:

  - 事务内更新：

    ```javascript
    rs0:PRIMARY> coll.updateOne({x: 1}, {$set: {y: 1}});
    { "acknowledged" : true, "matchedCount" : 1, "modifiedCount" : 1 }
    ```

  - 在事务内查询:

    ```javascript
    rs0:PRIMARY> coll.find()
    { "_id" : ObjectId("6385e173e4c725a1336fff4d"), "x" : 1, "y" : 1 }
    { "_id" : ObjectId("6385e173e4c725a1336fff4e"), "x" : 2 }
    ```

  - 在事务外查询:

    ```javascript
    rs0:PRIMARY> db.tx.find()
    { "_id" : ObjectId("6385e173e4c725a1336fff4d"), "x" : 1 }
    { "_id" : ObjectId("6385e173e4c725a1336fff4e"), "x" : 2 }
    ```

    可以看到**在事务外查询还是原来的老数据**。

  - 提交事务后，再查询:

    ```javascript
    rs0:PRIMARY>  session.commitTransaction()
    rs0:PRIMARY> db.tx.find()
    { "_id" : ObjectId("6385e173e4c725a1336fff4d"), "x" : 1, "y" : 1 }
    { "_id" : ObjectId("6385e173e4c725a1336fff4e"), "x" : 2 }
    ```

    可以看到**在事务外可以读到已经提交的事务**。

### 3.2 可重复读

以下操作在同一个命令行窗口完成。

- 删除测试表，并插入测试数据

  ```javascript
  # 删除表
  rs0:PRIMARY> db.tx.drop()
  true
  
  # 插入测试数据
  rs0:PRIMARY> db.tx.insertMany([{ x: 1 }, { x: 2 }]);
  {
          "acknowledged" : true,
          "insertedIds" : [
                  ObjectId("6385e286e4c725a1336fff4f"),
                  ObjectId("6385e286e4c725a1336fff50")
          ]
  }
  
  # 验证插入成功
  rs0:PRIMARY> db.tx.find()
  { "_id" : ObjectId("6385e286e4c725a1336fff4f"), "x" : 1 }
  { "_id" : ObjectId("6385e286e4c725a1336fff50"), "x" : 2 }
  ```

- 启动 session，开启事务并指定隔离级别，并在查询过程中在事务之外修改数据

  ```javascript
  # 开启session
  rs0:PRIMARY> var session = db.getMongo().startSession();
  
  # 开启事务并指定隔离级别
  rs0:PRIMARY> session.startTransaction({readConcern: {level: "snapshot"}, writeConcern: {w: "majority"}});
  
  # 获取表名
  rs0:PRIMARY> var coll = session.getDatabase('test').getCollection("tx");
  
  # 事务之内查询数据
  rs0:PRIMARY> coll.find({x: 1})
  { "_id" : ObjectId("6385e286e4c725a1336fff4f"), "x" : 1 }
  
  # 事务之外修改数据
  rs0:PRIMARY> db.tx.update({x: 1}, {$set: {y: 1}});
  WriteResult({ "nMatched" : 1, "nUpserted" : 0, "nModified" : 1 })
  
  # 事务之外查询
  rs0:PRIMARY> db.tx.find({x: 1});
  { "_id" : ObjectId("6385e286e4c725a1336fff4f"), "x" : 1, "y" : 1 }
  
  # 事务之内查询
  rs0:PRIMARY> coll.findOne({x: 1});
  { "_id" : ObjectId("6385e286e4c725a1336fff4f"), "x" : 1 }
  rs0:PRIMARY> coll.findOne({x: 1});
  { "_id" : ObjectId("6385e286e4c725a1336fff4f"), "x" : 1 }
  rs0:PRIMARY> coll.findOne({x: 1});
  { "_id" : ObjectId("6385e286e4c725a1336fff4f"), "x" : 1 }
  ```

  可以看到在 MongoDB 中可以通过上面的方式来实现比较高的隔离级别：**可重复读**。

## 四. 事务写机制

MongoDB 的事务错误处理机制不同于关系数据库，会有以下两种情况发生：

- 写冲突：当一个事务开始后，如果事务要修改的文档在事务外部被修改过，则事务修改这个文档时会触发 `Abort` 错误，因为此时的修改冲突了，这种情况下，只需要简单地重做事务就可以了。
- 写等待：如果一个事务已经开始修改一个文档，在事务以外尝试修改同一个文档，则事务以外的修改会等待事务完成才能继续进行。

### 4.1 写冲突示例

- 进入主节点，准备文档：

  ```javascript
  use test
  db.tx.drop();
  db.tx.insertMany([
  {x: 1}, 
  {x: 2}
  ]);
  ```

- 开启两个 mongo shell 窗口（都在主节点上），在两个窗口中分别执行以下语句：

  ```javascript
    use test
    var session = db.getMongo().startSession();
    session.startTransaction({readConcern: {level: "snapshot"}, writeConcern: {w: "majority"}});
    var coll = session.getDatabase('test').getCollection("tx");
  ```

- 在一个窗口中执行：

  ```javascript
  // 正常结束
  rs0:PRIMARY> coll.updateOne({x: 1}, {$set: {y: 1}});
  { "acknowledged" : true, "matchedCount" : 1, "modifiedCount" : 1 }  
  ```

- 在另一个窗口中执行：

  ```javascript
  // 写冲突，解决方案：重启事务
  // 可以看到它提示该条数据已经被另一个事务锁定正在写，本事务是不能写了，除非另一个事务提交
  rs0:PRIMARY> coll.updateOne({x: 1}, {$set: {y: 2}});
  2022-12-13T14:21:48.346+0800 E  QUERY    [js] uncaught exception: WriteCommandError({
          "errorLabels" : [
                  "TransientTransactionError"
          ],
          "operationTime" : Timestamp(1670912499, 1),
          "ok" : 0,
          "errmsg" : "WriteConflict",
          "code" : 112,
          "codeName" : "WriteConflict",
          "$clusterTime" : {
                  "clusterTime" : Timestamp(1670912499, 1),
                  "signature" : {
                          "hash" : BinData(0,"AAAAAAAAAAAAAAAAAAAAAAAAAAA="),
                          "keyId" : NumberLong(0)
                  }
          }
  })
  ```

- 在第一个窗口中提交事务：

  ```javascript
  rs0:PRIMARY> session.commitTransaction()
  ```

- 在加一个窗口再次重启事务提交：

  ```javascript
  rs0:PRIMARY> session.abortTransaction()
  rs0:PRIMARY> session.startTransaction({readConcern: {level: "snapshot"}, writeConcern: {w: "majority"}});
  rs0:PRIMARY> var coll = session.getDatabase('test').getCollection("tx");
  rs0:PRIMARY> coll.updateOne({x: 1}, {$set: {y: 2}});
  { "acknowledged" : true, "matchedCount" : 1, "modifiedCount" : 1 }
  rs0:PRIMARY> session.commitTransaction()
  ```

### 4.2 写等待示例

- 进入主节点，准备文档：

  ```javascript
  use test
  db.tx.drop();
  db.tx.insertMany([{
      x: 1
  }, {
      x: 2
  }]);
  ```

- 在第 1 个窗口中执行，事务正常提交：

  ```javascript
  rs0:PRIMARY> use test
  switched to db test
  rs0:PRIMARY> var session = db.getMongo().startSession();
  rs0:PRIMARY> session.startTransaction({readConcern: {level: "snapshot"}, writeConcern: {w: "majority"}});
  rs0:PRIMARY> var coll = session.getDatabase('test').getCollection("tx");
  rs0:PRIMARY> coll.updateOne({x: 1}, {$set: {y: 1}}); // 正常结束
  { "acknowledged" : true, "matchedCount" : 1, "modifiedCount" : 1 }
  ```

- 在第 2 个窗口中执行，更新同一条数据，异常：

  ```shell
  rs0:PRIMARY> use test
  switched to db test
  rs0:PRIMARY> var session = db.getMongo().startSession();
  session.startTransaction({readConcern: {level: "snapshot"}, writeConcern: {w: "majority"}});
  rs0:PRIMARY> session.startTransaction({readConcern: {level: "snapshot"}, writeConcern: {w: "majority"}});
  rs0:PRIMARY> var coll = session.getDatabase('test').getCollection("tx");
  rs0:PRIMARY> 
  rs0:PRIMARY> coll.updateOne({x: 1}, {$set: {y: 2}});
  2022-12-13T15:02:15.769+0800 E  QUERY    [js] uncaught exception: WriteCommandError({
          "errorLabels" : [
                  "TransientTransactionError"
          ],
          "operationTime" : Timestamp(1670914930, 1),
          "ok" : 0,
          "errmsg" : "WriteConflict",
          "code" : 112,
          "codeName" : "WriteConflict",
          "$clusterTime" : {
                  "clusterTime" : Timestamp(1670914930, 1),
                  "signature" : {
                          "hash" : BinData(0,"AAAAAAAAAAAAAAAAAAAAAAAAAAA="),
                          "keyId" : NumberLong(0)
                  }
          }
  }) 
  ```

- 在第 3 个窗口中执行，事务外更新，需等待：

  ```shell
  rs0:PRIMARY> db.tx.updateOne({x: 1}, {$set: {y: 3}}); // 阻塞等待
  ```

- 在原窗口中执行

  ```shell
  session.commitTransaction();
  ```

## 五. 总结

- 可以实现和关系型数据库类似的事务场景
- 必须使用与 `MongoDB 4.2` 兼容的驱动
- 事务默认必须在 60 秒（可调）内完成，否则将被取消
- 涉及事务的分片不能使用仲裁节点
- 事务会影响 `chunk` 迁移效率。正在迁移的 `chunk` 也可能造成事务提交失败（重试即可）
- 多文档事务中的读操作必须使用主节点读
- `readConcern` 只应该在事务级别设置，不能设置在每次读写操作上

> 参考文档：https://www.mongodb.com/docs/v4.2/core/transactions/
>
> 本文转载至：[MongoDB 多文档事务 | 一代键客 (zhangquan.me)](https://zhangquan.me/2023/03/06/mongodb-duo-wen-dang-shi-wu/)