# Java中NAN和Infinity问题

## int除零问题

```java
int j = 1 / 0;
```

会抛出`ArithmeticException`异常：

```java
Exception in thread "main" java.lang.ArithmeticException: / by zero
```

## float、double除零问题

```java
float i = (float)1.0 / 0;//Infinity
float j = (float)0.0 / 0;//NaN
```

```java
double i = 1.0 / 0; //Infinity
double j = 0.0 / 0; //NaN
```

double中除零时**不会**抛出`ArithmeticException`异常。`1.0 / 0`会返回`Infinity`；`0.0 / 0`会返回NAN。