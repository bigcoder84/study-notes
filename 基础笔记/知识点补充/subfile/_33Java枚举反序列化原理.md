# 枚举反序列化原理

> https://docs.oracle.com/javase/1.5.0/docs/guide/serialization/spec/serial-arch.html#enum

> Enum constants are serialized differently than ordinary serializable or externalizable objects. The serialized form of an enum constant consists solely of its name; field values of the constant are not present in the form. To serialize an enum constant, `ObjectOutputStream` writes the value returned by the enum constant's `name` method. To deserialize an enum constant, `ObjectInputStream` reads the constant name from the stream; the deserialized constant is then obtained by calling the `java.lang.Enum.valueOf` method, passing the constant's enum type along with the received constant name as arguments. Like other serializable or externalizable objects, enum constants can function as the targets of back references appearing subsequently in the serialization stream.
>
> The process by which enum constants are serialized cannot be customized: any class-specific `writeObject`, `readObject`, `readObjectNoData`, `writeReplace`, and `readResolve` methods defined by enum types are ignored during serialization and deserialization. Similarly, any `serialPersistentFields` or `serialVersionUID` field declarations are also ignored--all enum types have a fixed `serialVersionUID` of `0L`. Documenting serializable fields and data for enum types is unnecessary, since there is no variation in the type of data sent.

枚举常量的序列化方式不同于普通的可序列化或可外部化对象。枚举常量的序列化仅依靠其`name`组成（所有枚举都会继承Enum类，具体请参考枚举底层原理）;该常量的值在表单中不会存在。为了序列化一个enum常量，ObjectOutputStream写入由enum常量的name方法返回的值。为了反序列化enum常量，ObjectInputStream从流中读取常量名称;然后通过调用java.lang.Enum.valueOf获得反序列化的常量。将常量的enum类型和接收到的常量名称作为参数传递。与其他可序列化或可外部化的对象一样，enum常量可以作为随后出现在序列化流中的反向引用的目标。

枚举常量序列化的过程不能自定义:枚举类型定义的任何类特定的writeObject、readObject、readObjectNoData、writeReplace和readResolve方法在序列化和反序列化过程中被忽略。类似地，任何serialPersistentFields或serialVersionUID字段声明也会被忽略——所有enum类型都有一个固定的serialVersionUID 0L。为enum类型记录可序列化的字段和数据是不必要的，因为发送的数据类型没有变化。