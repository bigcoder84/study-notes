drop table sc;
drop table course;
drop table student;
drop table teacher;
drop table dep;

CREATE TABLE DEP
       (DNO NUMBER(2),
        DNAME VARCHAR2(30),
        DIRECTOR NUMBER(4),
        TEL   VARCHAR2(8));

CREATE TABLE TEACHER
       (TNO NUMBER(4),
        TNAME VARCHAR2(10),
        TITLE VARCHAR2(20),
        HIREDATE DATE,
        SAL NUMBER(7,2),
        BONUS  NUMBER(7,2),
   	MGR NUMBER(4),             
        DEPTNO NUMBER(2));

CREATE TABLE student
       (sno NUMBER(6),
        sname VARCHAR2(8),
        sex VARCHAR2(2),
        birth   DATE,
        passwd  VARCHAR2(8),
        dno  NUMBER(2));
        
CREATE TABLE course
       (cno VARCHAR2(8),
        cname VARCHAR2(20),
        credit NUMBER(1),
        ctime  NUMBER(2),
        quota  NUMBER(3));
        
CREATE TABLE sc
       (sno NUMBER(6),
        cno  VARCHAR2(8),
        grade NUMBER(3));        
        
alter table dep add (constraint pk_deptno primary key(dno));
alter table dep add(constraint dno_number_check check(dno>=10 and dno<=50));
alter table dep modify(tel default 62795032);
alter table student add (constraint pk_sno primary key(sno));
alter table student add(constraint sex_check check(sex='男' or sex='女'));
alter table student modify(birth default sysdate);
alter table course add (constraint pk_cno primary key(cno));
alter table sc add (constraint pk_key primary key(cno,sno));
alter table teacher add (constraint pk_tno primary key(tno));
alter table sc add (FOREIGN KEY(cno) REFERENCES course(cno));
alter table sc add (FOREIGN KEY(sno) REFERENCES student(sno));
alter table student add (FOREIGN KEY(dno) REFERENCES dep(dno));
alter table teacher add (FOREIGN KEY(deptno) REFERENCES dep(dno));  

INSERT INTO DEP VALUES (10, '计算机系', 9469 , '62785234');
INSERT INTO DEP VALUES (20,'自动化系', 9581 , '62775234');
INSERT INTO DEP VALUES (30,'无线电系', 9791 , '62778932');
INSERT INTO DEP VALUES (40,'信息管理系', 9611, '62785520');
INSERT INTO DEP VALUES (50,'微纳电子系', 2031, '62797686');


INSERT INTO TEACHER VALUES(9468,'CHARLES','PROFESSOR','17-12月-2004',8000,1000,NULL,10);
INSERT INTO TEACHER VALUES(9469,'SMITH','PROFESSOR','17-12月-2004',5000,1000 ,9468,10);
INSERT INTO TEACHER VALUES(9470,'ALLEN','ASSOCIATE PROFESSOR', '20-2月-2003',4200,500,9469,10);
INSERT INTO TEACHER VALUES(9471,'WARD','LECTURER', '22-2月-2004',3000,300,9469,10);
INSERT INTO TEACHER VALUES(9581,'JONES','PROFESSOR ', '2-4月-2003',6500,1000,9468,20);
INSERT INTO TEACHER VALUES(9582,'MARTIN','ASSOCIATE PROFESSOR ','28-9月-2005',4000,800,9581,20);
INSERT INTO TEACHER VALUES(9583,'BLAKE','LECTURER ','1-5月-2006',3000,300,9581,20);
INSERT INTO TEACHER VALUES(9791,'CLARK','PROFESSO', '9-6月-2003',5500,NULL,9468,30);
INSERT INTO TEACHER VALUES(9792,'SCOTT','ASSOCIATE PROFESSOR ','09-12月-2004',4500,NULL,9791,30);
INSERT INTO TEACHER VALUES(9793,'BAGGY','LECTURER','17-11月-2004',3000,NULL,9791,30);
INSERT INTO TEACHER VALUES(9611,'TURNER','PROFESSOR ','8-9月-2005',6000,1000,9468,40);
INSERT INTO TEACHER VALUES(9612,'ADAMS','ASSOCIATE PROFESSO','12-1月-2004',4800,800,9611,40);
INSERT INTO TEACHER VALUES(9613,'JAMES','LECTURER','3-12月-2006',2800,200,9611,40);
INSERT INTO TEACHER VALUES(2031,'FORD','PROFESSOR','3-12月-2005',5500,NULL,9468,50);
INSERT INTO TEACHER VALUES(2032,'MILLER','ASSOCIATE PROFESSO','23-1月-2005',4300,NULL,2031,50);
INSERT INTO TEACHER VALUES(2033,'MIGEAL','LECTURER','23-1月-2006',2900,NULL,2031,50);
INSERT INTO TEACHER VALUES(2034,'PEGGY', 'LECTURER', '23-1月-2007',2500,NULL,2031,50);


insert into student(birth,sno,sname,sex,passwd,dno) values('01-8月 -10',1,'John','男','123456',10);
insert into student(birth,sno,sname,sex,passwd,dno) values('02-8月 -10',2,'Jacob','男','123456',10);
insert into student(birth,sno,sname,sex,passwd,dno) values('03-8月 -10',3,'Michael','男','123456',10);
insert into student(birth,sno,sname,sex,passwd,dno) values('04-8月 -10',4,'Joshua','男','123456',10);
insert into student(birth,sno,sname,sex,passwd,dno) values('05-8月 -10',5,'Ethan','男','123456',10);
insert into student(birth,sno,sname,sex,passwd,dno) values('06-8月 -10',6,'Matthew','男','123456',20);
insert into student(birth,sno,sname,sex,passwd,dno) values('07-8月 -10',7,'Daniel','男','123456',20);
insert into student(birth,sno,sname,sex,passwd,dno) values('08-8月 -10',8,'Chris','男','123456',20);
insert into student(birth,sno,sname,sex,passwd,dno) values('09-8月 -10',9,'Andrew','男','123456',30);
insert into student(birth,sno,sname,sex,passwd,dno) values('10-8月 -10',10,'Anthony','男','123456',30);
insert into student(birth,sno,sname,sex,passwd,dno) values('11-8月 -10',11,'William','男','123456',30);
insert into student(birth,sno,sname,sex,passwd,dno) values('12-8月 -10',12,'Joseph','男','123456',40);
insert into student(birth,sno,sname,sex,passwd,dno) values('13-8月 -10',13,'Alex','男','123456',40);
insert into student(birth,sno,sname,sex,passwd,dno) values('14-8月 -10',14,'David','男','123456',40);
insert into student(birth,sno,sname,sex,passwd,dno) values('15-8月 -10',15,'Ryan','男','123456',40);
insert into student(birth,sno,sname,sex,passwd,dno) values('16-8月 -10',16,'Noah','男','123456',40);
insert into student(birth,sno,sname,sex,passwd,dno) values('17-8月 -10',17,'James','男','123456',40);
insert into student(birth,sno,sname,sex,passwd,dno) values('18-8月 -10',18,'Nicholas','男','123456',50);
insert into student(birth,sno,sname,sex,passwd,dno) values('19-8月 -10',19,'Tyler','男','123456',50);
insert into student(birth,sno,sname,sex,passwd,dno) values('20-8月 -10',20,'Logan','男','123456',50);
insert into student(birth,sno,sname,sex,passwd,dno) values('21-8月 -10',21,'Emily','女','123456',10);
insert into student(birth,sno,sname,sex,passwd,dno) values('22-8月 -10',22,'Emma','女','123456',10);
insert into student(birth,sno,sname,sex,passwd,dno) values('23-8月 -10',23,'Madis','女','123456',10);
insert into student(birth,sno,sname,sex,passwd,dno) values('24-8月 -10',24,'Isabe','女','123456',10);
insert into student(birth,sno,sname,sex,passwd,dno) values('25-8月 -10',25,'Ava','女','123456',10);
insert into student(birth,sno,sname,sex,passwd,dno) values('26-8月 -10',26,'Abigail','女','123456',20);
insert into student(birth,sno,sname,sex,passwd,dno) values('27-8月 -10',27,'Olivia','女','123456',20);
insert into student(birth,sno,sname,sex,passwd,dno) values('28-8月 -10',28,'Hannah','女','123456',20);
insert into student(birth,sno,sname,sex,passwd,dno) values('29-8月 -10',29,'Sophia','女','123456',30);
insert into student(birth,sno,sname,sex,passwd,dno) values('30-8月 -10',30,'Samant','女','123456',30);
insert into student(birth,sno,sname,sex,passwd,dno) values('31-8月 -10',31,'Elizab','女','123456',30);
insert into student(birth,sno,sname,sex,passwd,dno) values('01-7月 -10',32,'Ashley','女','123456',40);
insert into student(birth,sno,sname,sex,passwd,dno) values('02-7月 -10',33,'Mia','女','123456',40);
insert into student(birth,sno,sname,sex,passwd,dno) values('11-8月 -10',34,'Alexis','女','123456',40);
insert into student(birth,sno,sname,sex,passwd,dno) values('12-8月 -10',35,'Sarah','女','123456',40);
insert into student(birth,sno,sname,sex,passwd,dno) values('13-8月 -10',36,'Natalie','女','123456',40);
insert into student(birth,sno,sname,sex,passwd,dno) values('14-8月 -10',37,'Grace','女','123456',40);
insert into student(birth,sno,sname,sex,passwd,dno) values('15-8月 -10',38,'Chloe','女','123456',50);
insert into student(birth,sno,sname,sex,passwd,dno) values('16-8月 -10',39,'Alyssa','女','123456',50);
insert into student(birth,sno,sname,sex,passwd,dno) values('17-8月 -10',40,'Brianna','女','123456',50);         


insert into course values('c001','数据结构',3,10,100);
insert into course values('c002','Java语言',2,20,100);
insert into course values('c003','数字电路',3,30,100);
insert into course values('c004','模拟电路',3,40,100);
insert into course values('c005','信号与系统',4,50,100);
insert into course values('c006','C语言',3,60,100);
insert into course values('c007','高等数学',5,70,100);
insert into course values('c008','自动原理',1,80,100);
insert into course values('c009','数理方程',3,90,100);
insert into course values('c010','大学语文',2,61,100);
insert into course values('c011','机械制图',3,52,100);
insert into course values('c012','微机原理',3,43,100);
insert into course values('c013','通信基础',3,74,100);
insert into course values('c014','计算机原理',5,35,100);
insert into course values('c015','数据库',3,86,100);
insert into course values('c016','编译原理',2,97,100);
insert into course values('c017','大学物理',2,38,100);
insert into course values('c018','统计基础',4,50,100);
insert into course values('c019','线性代数',4,70,100);
insert into course values('c020','Linux基础',3,60,100);



insert into sc values(6,'c002',60);
insert into sc values(6,'c015',60);
insert into sc values(6,'c010',61);
insert into sc values(27,'c010',65);
insert into sc values(6,'c001',60);
insert into sc values(6,'c011',61);
insert into sc values(6,'c018',70);
insert into sc values(8,'c007',65);
insert into sc values(27,'c020',65);
insert into sc values(27,'c015',65);       
insert into sc values(26,'c015',55);   
insert into sc values(25,'c015',59);      
insert into sc values(1,'c017',65);
insert into sc values(2,'c017',66);
insert into sc values(3,'c017',67);
insert into sc values(4,'c017',68);
insert into sc values(5,'c017',69);
insert into sc values(6,'c017',70);
insert into sc values(7,'c017',71);
insert into sc values(8,'c017',72);
insert into sc values(9,'c017',73);
insert into sc values(10,'c017',74);
insert into sc values(11,'c017',75);
insert into sc values(12,'c017',76);
insert into sc values(13,'c017',77);
insert into sc values(14,'c017',78);
insert into sc values(15,'c017',79);
insert into sc values(16,'c017',80);
insert into sc values(17,'c017',81);
insert into sc values(18,'c017',82);
insert into sc values(19,'c017',83);
insert into sc values(20,'c017',84);
insert into sc values(21,'c017',85);
insert into sc values(22,'c017',86);
insert into sc values(23,'c017',87);
insert into sc values(24,'c017',88);
insert into sc values(25,'c017',89);
insert into sc values(26,'c017',90);
insert into sc values(27,'c017',89);
insert into sc values(28,'c017',88);
insert into sc values(29,'c017',87);
insert into sc values(30,'c017',86);
insert into sc values(31,'c017',85);
insert into sc values(32,'c017',84);
insert into sc values(33,'c017',83);
insert into sc values(34,'c017',82);
insert into sc values(35,'c017',81);
insert into sc values(36,'c017',80);
insert into sc values(37,'c017',79);
insert into sc values(38,'c017',78);
insert into sc values(39,'c017',77);
insert into sc values(40,'c017',76);
commit;