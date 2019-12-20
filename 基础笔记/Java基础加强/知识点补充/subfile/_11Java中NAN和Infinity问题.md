# Java中NAN和Infinity问题

## int除零问题

```java
int j = 1 / 0;
```

会抛出`ArithmeticException`异常：

```java
Exception in thread "main" java.lang.ArithmeticException: / by zero
```

## float除零问题

```java
float i = (float)1.0 / 0;
float j = (float)0.0 / 0;
```

会抛出`ArithmeticException`异常

## double除零问题

```java
double i = 1.0 / 0; //Infinity
double j = 0.0 / 0; //NaN
```

double中除零时不会抛出`ArithmeticException`异常。