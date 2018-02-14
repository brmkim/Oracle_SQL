DELETE FROM emp WHERE ename = 'SCOTT';
COMMIT;
-----
----- CHAPTER 3: GROUP FUNCTIONS "복수행 함수(그룹함수)"
-----
SELECT deptno, NULL job, round(avg(sal), 1) avg_sal, count(*) cnt_emp FROM emp
GROUP BY deptno
UNION ALL
SELECT deptno, job, ROUND(AVG(sal),1) avg_sal, COUNT(*) cnt_emp from emp
GROUP BY deptno, job
UNION ALL
SELECT NULL deptno, NULL job, ROUND(AVG(sal),1) avg_sal, COUNT(*) cnt_emp from emp
GROUP BY deptno, job;

-- rollup
SELECT deptno, job, ROUND(AVG(sal), 1) avg_sal, COUNT(*) cnt_emp FROM emp 
GROUP BY ROLLUP(deptno, job);

SELECT deptno, position, COUNT(*), SUM(PAY) FROM professor 
GROUP BY position, ROLLUP(deptno);

-- PIVOT 함수를 사용하지 않고 달력 만들기
select max(decode(day, 'SUN', dayno)) SUN,
    max(decode(day, 'MON', dayno)) MON,
    max(decode(day, 'TUE', dayno)) TUE,
    max(decode(day, 'WED', dayno)) WED,
    max(decode(day, 'THU', dayno)) THU,
    max(decode(day, 'FRI', dayno)) FRI,
    max(decode(day, 'SAT', dayno)) SAT
    from cal group by weekno order by weekno;
    
-- PIVOT 함수를 사용하여 달력 만들기
SELECT * FROM (SELECT weekno "WEEK", day, dayno FROM CAL)
    PIVOT( MAX(dayno) FOR day IN ('SUN' AS "SUN",
                                  'MON' AS "MON",
                                  'TUE' AS "TUE",
                                  'WED' AS "WED",
                                  'THU' AS "THU",
                                  'FRI' AS "FRI",
                                  'SAT' AS "SAT" )
           )
    ORDER BY "WEEK";

-- EMP테이블에서 부서별로 각 직급별 인원이 몇 명인지 계산하기 (PIVT() 함수사용)
SELECT * FROM (SELECT deptno, job, empno FROM EMP)
    PIVOT( COUNT(empno) FOR job IN ('CLERK' AS "CLERK",
                                    'MANAGER' AS "MANAGER",
                                    'PRESIDENT' AS "PRESIDENT",
                                    'ANALYST' AS "ANALYST",
                                    'SALESMAN' AS "SALESMAN")
          )
    ORDER BY deptno;

-- UNPIVOT()함수 TEST
CREATE TABLE unpivot AS SELECT * FROM (SELECT deptno, job, empno FROM emp)
    PIVOT(
        COUNT(empno) FOR job IN ('CLERK' AS "CLERK",
                                    'MANAGER' AS "MANAGER",
                                    'PRESIDENT' AS "PRESIDENT",
                                    'ANALYST' AS "ANALYST",
                                    'SALESMAN' AS "SALESMAN")
        );
SELECT * FROM unpivot;

SELECT * FROM unpivot UNPIVOT(empno FOR job IN (CLERK, MANAGER, PRESIDENT, ANALYST, SALESMAN));

-- RANK() 함수 이용예
SELECT empno, ename, sal, 
    RANK() OVER (ORDER BY sal) AS RANK_ASC, 
    RANK() OVER(ORDER BY sal DESC) AS RANK_DESC
FROM emp;

SELECT empno, ename, sal, 
    RANK() OVER (ORDER BY sal DESC)
FROM emp WHERE deptno = 10;

SELECT empno, ename, sal, deptno, RANK() OVER (PARTITION BY deptno ORDER BY SAL DESC) AS rank
FROM emp;

SELECT empno, ename, sal, deptno, RANK() OVER  (PARTITION BY deptno, job ORDER BY sal DESC) AS rank
FROM emp;

-- DENSE_RANK() : RANK를 하되 동일한 순위를 하나의 건수로 취급하므로 연속된 순위를 보여준다
SELECT empno, ename, sal, 
    RANK() OVER (ORDER BY sal DESC) sal_rank, 
    DENSE_RANK() OVER (ORDER BY sal DESC) sal_dense_rank
FROM emp;

-- ROW_NUMBER(): RANK()와 DENSE_RANK()는 동일한 값에 같은 순위를 부여하지만 ROW_NUMBER()는 
-- 동일한 값이라도 고유한 순위를 부여한다.
SELECT empno, ename, sal, 
    RANK() OVER (ORDER BY sal DESC) sal_rank, 
    DENSE_RANK() OVER (ORDER BY sal DESC) sal_dense_rank,
    ROW_NUMBER() OVER (ORDER BY sal DESC) sal_row_num
FROM emp;

-- SUM() OVER: 누적합계 구할때 이용. 이용 예
SELECT p_date, p_code, p_qty, p_total, SUM(p_total) OVER (ORDER BY p_total) "TOTAL"
FROM panmae WHERE p_store = 1000;

SELECT p_date, p_code, p_qty, p_total, SUM(p_total) OVER (PARTITION BY p_code ORDER BY p_total) "TOTAL"
FROM panmae WHERE p_store = 1000;

SELECT p_code, p_store, p_date, p_qty, p_total, 
    SUM(p_total) OVER (PARTITION BY p_code, p_store ORDER BY p_total) "TOTAL"
FROM panmae;

-- RATIO_TO_REPORT() 함수이용한 판매비율 구하기
-- panmae TABLE에서 100번 제품의 판매 내역과 각 판매점별로 판매 비중을 구해본다

SELECT p_code, SUM(SUM(p_qty)) OVER() "TOTAL_QTY",
               SUM(SUM(p_total)) OVER() "TOTAL_PRICE", p_store, p_qty, p_total,
               ROUND( (RATIO_TO_REPORT(SUM(p_qty)) OVER()) *100, 2) "QTY_%",
               ROUND( (RATIO_TO_REPORT(SUM(p_total)) OVER()) *100, 2) "TOTAL_%"
FROM panmae WHERE p_code = 100 
GROUP BY p_code, p_store, p_qty, p_total;

-- LAG() 함수를 이용한 예제
-- 1) 1000번 판매점의 일자별 판매 내역과 금액 및 전일 판매 수량과 금액차이 계산
SELECT p_store, p_date, p_code, p_qty, 
    LAG(p_qty, 1) OVER (ORDER BY p_date) "D-1 QTY",
    p_qty - LAG(p_qty, 1) OVER (ORDER BY p_date) "DIFF QTY",
    p_total,
    LAG(p_total, 1) OVER (ORDER BY p_date) "D-1 PRICE",
    p_total - LAG(p_total, 1) OVER (ORDER BY p_date) "DIFF PRICE"
FROM panmae WHERE p_store = 1000; 
-- 2) 모든 판매점 별로 다 출력
SELECT p_store, p_date, p_code, p_qty, 
    LAG(p_qty, 1) OVER (PARTITION BY p_store ORDER BY p_date) "D-1 QTY",
    p_qty - LAG(p_qty, 1) OVER (PARTITION BY p_store ORDER BY p_date) "DIFF QTY",
    p_total,
    LAG(p_total, 1) OVER (PARTITION BY p_store ORDER BY p_date) "D-1 PRICE",
    p_total - LAG(p_total, 1) OVER (PARTITION BY p_store ORDER BY p_date) "DIFF PRICE"
FROM panmae; 
--
-- P.213 연습문제 
--
-- 1. [DONE] 
SELECT MAX(SUM(NVL(sal,0) + NVL(comm,0))) "MAX", 
       MIN(SUM(NVL(sal,0) + NVL(comm,0))) "MIN",
       TO_CHAR(AVG(SUM(NVL(sal,0) + NVL(comm,0))), '9999.9') "AVG"
FROM emp GROUP BY empno ;

-- 2. [DONE] 
SELECT COUNT(name) "TOTAL",
       COUNT(DECODE(SUBSTR(TO_CHAR(birthday, 'YY/MM/DD'), 4, 2), 01, 'JAN')) "JAN",
       COUNT(DECODE(SUBSTR(TO_CHAR(birthday, 'YY/MM/DD'), 4, 2), 02, 'FEB')) "FEB",
       COUNT(DECODE(SUBSTR(TO_CHAR(birthday, 'YY/MM/DD'), 4, 2), 03, 'MAR')) "MAR",
       COUNT(DECODE(SUBSTR(TO_CHAR(birthday, 'YY/MM/DD'), 4, 2), 04, 'APR')) "APR",
       COUNT(DECODE(SUBSTR(TO_CHAR(birthday, 'YY/MM/DD'), 4, 2), 05, 'MAY')) "MAY",
       COUNT(DECODE(SUBSTR(TO_CHAR(birthday, 'YY/MM/DD'), 4, 2), 06, 'JUN')) "JUN",
       COUNT(DECODE(SUBSTR(TO_CHAR(birthday, 'YY/MM/DD'), 4, 2), 07, 'JUL')) "JUL",
       COUNT(DECODE(SUBSTR(TO_CHAR(birthday, 'YY/MM/DD'), 4, 2), 08, 'AUG')) "AUG",
       COUNT(DECODE(SUBSTR(TO_CHAR(birthday, 'YY/MM/DD'), 4, 2), 09, 'SEP')) "SEP",
       COUNT(DECODE(SUBSTR(TO_CHAR(birthday, 'YY/MM/DD'), 4, 2), 10, 'OCT')) "OCT",
       COUNT(DECODE(SUBSTR(TO_CHAR(birthday, 'YY/MM/DD'), 4, 2), 11, 'NOV')) "NOV",
       COUNT(DECODE(SUBSTR(TO_CHAR(birthday, 'YY/MM/DD'), 4, 2), 12, 'DEC')) "DEC"         
FROM student;

--3. [DONE] 
SELECT COUNT(tel) "TOTAL",
    COUNT(DECODE(SUBSTR(tel, 1, INSTR(tel, ')')-1), 02, 'SEOUL')) "SEOUL",
    COUNT(DECODE(SUBSTR(tel, 1, INSTR(tel, ')')-1), 031, 'GYEONGGI')) "GYENGGI",
    COUNT(DECODE(SUBSTR(tel, 1, INSTR(tel, ')')-1), 051, 'BUSAN')) "BUSAN",
    COUNT(DECODE(SUBSTR(tel, 1, INSTR(tel, ')')-1), 052, 'ULSAN')) "ULSAN",
    COUNT(DECODE(SUBSTR(tel, 1, INSTR(tel, ')')-1), 053, 'DAEGU')) "DAEGU",
    COUNT(DECODE(SUBSTR(tel, 1, INSTR(tel, ')')-1), 055, 'GYEONGNAM')) "GYEONGNAM"

FROM student;

--4. [unfinished]
INSERT INTO emp(empno, deptno, ename, sal) VALUES(1000, 10, 'Tiger', 3600);
INSERT INTO emp(empno, deptno, ename, sal) VALUES(2000, 10, 'Cat', 3000);
COMMIT;

SELECT * FROM (SELECT deptno, job, sal FROM emp)
    PIVOT( SUM(NVL(sal, 0)) FOR job IN ('CLERK' "CLERK", 'MANAGER' "MANAGER", 'PRESIDENT' "PRESIDENT", 
                                                'ANALYST' "ANALYST", 'SALESMAN' "SALESMAN")
          )
          -- TO BE CONTINUED
ORDER BY deptno;

SELECT deptno, SUM(NVL(sal, 0)) OVER(PARTITION BY deptno) "DEPT_TOTAL" FROM emp;
SELECT deptno, job, SUM(NVL(sal, 0)) OVER(PARTITION BY job) "JOB_TOTAL" FROM emp ORDER BY job;
SELECT deptno, job, SUM(NVL(sal, 0)) "TOTAL" FROM emp  GROUP BY job, ROLLUP(deptno) ORDER BY deptno;

SELECT deptno, job, SUM(NVL(sal, 0)) "TOTAL" FROM emp GROUP BY GROUPING SETS(deptno, job);
-- 5. [DONE]
SELECT deptno, ename, sal, SUM(sal) OVER (ORDER BY sal) "TOTAL" 
    FROM emp
    ORDER BY sal ASC;

-- 6. [unfinished]
SELECT * FROM (SELECT price, name FROM FRUIT) 
    PIVOT
    ( MAX(price) FOR name IN ('APPLE' "APPLE", 'GRAPE' "GRAPE", 'ORANGE' "ORANGE")
    );
DESC FRUIT;
SELECT * FROM FRUIT;

-- 7. PROB 3 + RATIO [UNFINISHED]
SELECT COUNT(tel) "TOTAL",
    COUNT(DECODE(SUBSTR(tel, 1, INSTR(tel, ')')-1), 02, 'SEOUL')) "SEOUL",
    COUNT(DECODE(SUBSTR(tel, 1, INSTR(tel, ')')-1), 031, 'GYEONGGI')) "GYENGGI",
    COUNT(DECODE(SUBSTR(tel, 1, INSTR(tel, ')')-1), 051, 'BUSAN')) "BUSAN",
    COUNT(DECODE(SUBSTR(tel, 1, INSTR(tel, ')')-1), 052, 'ULSAN')) "ULSAN",
    COUNT(DECODE(SUBSTR(tel, 1, INSTR(tel, ')')-1), 053, 'DAEGU')) "DAEGU",
    COUNT(DECODE(SUBSTR(tel, 1, INSTR(tel, ')')-1), 055, 'GYEONGNAM')) "GYEONGNAM"
FROM student;

-- 8. [DONE]
SELECT deptno, ename, sal, SUM(NVL(sal, 0)) OVER (PARTITION BY deptno ORDER BY sal) "TOTAL" 
    FROM emp
    ORDER BY deptno ASC;
    
-- 9. [DONE]
SELECT deptno, ename, sal, SUM(NVL(sal, 0)) OVER() "TOTAL_SAL", ROUND(RATIO_TO_REPORT(sal) OVER() * 100, 2) "%" 
    FROM emp ORDER BY sal DESC;

-- 10. [DONE]
SELECT deptno, ename, sal, SUM(NVL(sal, 0)) OVER(PARTITION BY deptno) "SUM_DEPT", 
    ROUND(RATIO_TO_REPORT(sal) OVER(PARTITION BY deptno) * 100, 2) "%" 
    FROM emp ORDER BY deptno ASC;
    
-- 11. [DONE]
SELECT l_date "대출일자", l_code "대출종목코드", l_qty "대출건수", l_total "대출총액",
       SUM(l_total) OVER (ORDER BY l_date) "누적대출금액" 
       FROM loan WHERE l_store = 1000 ORDER BY L_DATE;

-- 12. [DONE]
SELECT l_code "대출종목코드", l_store "대출지점", l_date "대출일자", l_qty "대출건수", l_total "대출액",
       SUM(l_total) OVER (PARTITION BY l_store ORDER BY l_code, l_total) "누적대출금액" 
       FROM loan ORDER BY l_code, l_store;
       
-- 13. [DONE]
SELECT l_date "대출일자", l_code "대출구분코드", l_qty "대출건수",l_total "대출총액",
        SUM(l_total) OVER ( PARTITION BY l_code ORDER BY l_total) "누적대출금액" 
        FROM loan 
        WHERE l_store = 1000;
        
-- 14. [DONE]
SELECT deptno, name, pay, SUM(pay) OVER() "TOTAL PAY", ROUND(RATIO_TO_REPORT(pay) OVER() * 100, 2) "RATIO %"
        FROM professor
        ORDER BY "RATIO %" DESC;

-- 15. [DONE]
SELECT deptno, name, pay, SUM(pay) OVER (PARTITION BY deptno), 
        ROUND(RATIO_TO_REPORT(pay) OVER(PARTITION BY deptno) * 100, 2) "RATIO(%)"
        FROM professor;
        
-----
----- CHAPTER 4. JOIN
-----

--1) Cartesian Product

CREATE TABLE cat_a(no NUMBER, name VARCHAR2(1));
INSERT INTO cat_a VALUES(1, 'A');
INSERT INTO cat_a VALUES(2, 'B');
CREATE TABLE cat_b(no NUMBER, name VARCHAR2(1));
INSERT INTO cat_b VALUES(1, 'C');
INSERT INTO cat_b VALUES(2, 'D');
CREATE TABLE cat_c(no NUMBER, name VARCHAR2(1));
INSERT INTO cat_c VALUES(1, 'E');
INSERT INTO cat_c VALUES(2, 'F');
COMMIT;

SELECT a.name, b.name FROM cat_a a, cat_b b WHERE a.no = b.no;  -- good
SELECT a.name, b.name FROM cat_a a, cat_b b;   -- Output: cat_a X cat_b 
SELECT a.name, b.name, c.name FROM cat_a a, cat_b b, cat_c c 
    WHERE a.no = b.no AND a.no = c.no;  -- good
SELECT a.name, b.name, c.name FROM cat_a a, cat_b b, cat_c c 
    WHERE a.no = b.no;  -- left a.no = c.no out
    
-- 2) EQUI JOIN (등가 조인)
-- JOIN where it uses "="(equal) operator
SELECT e.empno, e.ename, d.dname FROM emp e, dept d WHERE e.deptno = d.deptno;
SELECT s.name "STUDENT NAME", p.name "PROFESSOR NAME" 
    FROM student s, professor p WHERE s.profno = p.profno;
SELECT s.name "STUDENT NAME", d.dname "DEPT_NAME", p.name "PROF_NAME" 
    FROM student s, department d, professor p
    WHERE s.deptno1 = d.deptno 
    AND s.profno = p.profno;
SELECT s.name "STUDENT NAME", p.name "PROF_NAME" 
    FROM student s, professor p 
    WHERE s.deptno1 = 101 AND s.profno = p.profno; 

-- 3) NON-EQUI JOIN (비등가 조인)
-- JOIN where joining operator is anything but "="
desc customer;
desc gift;
SELECT c.gname "CUST_NAME", TO_CHAR(c.point, '999,999') "POINT", g.gname "GIFT_NAME" 
    FROM customer c, gift g
    WHERE c.point BETWEEN g.g_start AND g.g_end;
 -- Or use comparison operators(<=, >=) for better performance --
SELECT c.gname "CUST_NAME", TO_CHAR(c.point, '999,999') "POINT", g.gname "GIFT_NAME" 
    FROM customer c, gift g
    WHERE c.point >= g.g_start AND c.point <= g.g_end;

SELECT s.name "STU_NAME", sc.total "SCORE", g.grade "GPA"
    FROM student s, score sc, hakjum g
    WHERE s.studno = sc.studno 
    AND sc.total >= g.min_point 
    AND sc.total <= g.max_point;
    
-- 4) OUTER JOIN
-- Data exists on one table but no on another... Outer join results in printing all data of the table
-- from which data exist
SELECT s.name "STUDENT NAME", p.name "PROFESSOR NAME" 
    FROM student s, professor p 
    WHERE s.profno = p.profno(+); 
    
-- ANSI OUTER JOIN
SELECT s.name "STUDENT NAME", p.name "PROFESSOR NAME" 
    FROM student s LEFT OUTER JOIN professor p 
    ON s.profno = p.profno; 

-- Want two Outer Joins (full outer join): OJ union OJ 
SELECT s.name "STUDENT NAME", p.name "PROFESSOR NAME" 
    FROM student s, professor p 
    WHERE s.profno = p.profno(+)    
    UNION
SELECT s.name "STUDENT NAME", p.name "PROFESSOR NAME" 
    FROM student s, professor p 
    WHERE s.profno(+) = p.profno;  
    
-- ANSI FULL OUTER JOIN
SELECT s.name "STUDENT NAME", p.name "PROFESSOR NAME" 
    FROM student s FULL OUTER JOIN professor p 
    ON s.profno = p.profno; 

-- Caution for Oracle Outer Join: outer join side column must have (+) operator for all other cond.
SELECT d.deptno, d.dname, d.loc, e.empno, e.ename, e.sal
    FROM dept d, emp e
    WHERE d.deptno = e.deptno(+)
    AND e.deptno(+) = 20 ;

-- Caution for ANSI Outer Join:
SELECT e.empno, e.ename, e.job, d.deptno, d.dname, d.loc
    FROM emp e LEFT OUTER JOIN dept d
    ON ( e.deptno = d.deptno 
        and d.loc = 'CHICAGO'       -- No WHERE clause so choose all data from emp table,
        and e.job = 'CLERK' );      -- do outer join according to ON condition on all data from emp
        
SELECT e.empno, e.ename, e.job, d.deptno, d.dname, d.loc
    FROM emp e LEFT OUTER JOIN dept d
    ON ( e.deptno = d.deptno 
        and d.loc = 'CHICAGO')            --- Get data from emp table which meet WHERE condition, 
    WHERE e.job = 'CLERK';              --- among those filtered data, do the outer join according to the ON cond.
 
-- 5) SELF JOIN    
-- Join within one table: use different aliases for the same table. 

SELECT a.ename "ENAME", b.ename "MGR_ENAME" FROM emp a, emp b WHERE a.mgr = b.empno;

--- p.258~261 Chapter Exercise
-- 1. [DONE]
SELECT s.name "STU_NAME", s.deptno1, d.dname "DEPT_NAME"
    FROM student s, department d
    WHERE s.deptno1 = d.deptno;
-- 2. [DONE]
SELECT e.name "NAME", e.position "POSITION", TO_CHAR(e.pay, '999,999,999') "PAY", 
    TO_CHAR(p.s_pay, '999,999,999') "LOW PAY", TO_CHAR(p.e_pay, '999,999,999') "HIGH PAY"
    FROM emp2 e, p_grade p
    WHERE e.position = p.position;
-- 3. [not done]
SELECT e.name "NAME", TRUNC((SYSDATE - e.birthday) / 365) "AGE", e.position "CURR_POSITION"
    FROM emp2 e, p_grade p
    WHERE e.position = p.position(+) ;
    --AND TRUNC((SYSDATE - e.birthday) / 365) >= p.s_age 
    --AND TRUNC((SYSDATE - e.birthday) / 365) <= p.e_age;
    
select * from p_grade;
select * from emp2;

-- 4. [DONE]
SELECT c.gname, c.point, g.gname
    FROM customer c, gift g
    WHERE c.point >= g.g_start 
    AND c.point <= g.g_end 
    AND g.gname = 'Notebook';
    
-- 5. [not done]
SELECT p1.profno, p1.name, p1.hiredate, p2.name,
       TO_NUMBER(TO_CHAR(p2.hiredate, 'yyyymmdd')) - TO_NUMBER(TO_CHAR(p1.hiredate, 'yyyymmdd')) "DIFF"
    FROM professor p1, professor p2;
    --WHERE TO_NUMBER(TO_CHAR(p2.hiredate, 'yyyymmdd')) - TO_NUMBER(TO_CHAR(p1.hiredate, 'yyyymmdd')) < 0 ;
-- 6.

---
--- Chapter 5(DML), 6(DDL, Dictionary) -- Pass for now
---

---
--- Chapter 7. Constraints
---
CREATE TABLE new_emp1(
    no NUMBER(4) CONSTRAINT emp1_no_pk PRIMARY KEY,    -- "emp1_no_pk" Name of constraint. It gets saved in the dictionary
    name VARCHAR2(20) CONSTRAINT emp1_name_nn NOT NULL,
    jumin VARCHAR2(13) CONSTRAINT emp1_jumin_nn NOT NULL CONSTRAINT emp_jumin_uk UNIQUE, -- no "," between multiple constraints
    loc_code NUMBER(1) CONSTRAINT emp1_area_ck CHECK(loc_code < 5),
    deptno VARCHAR2(6) CONSTRAINT emp1_deptno_fk REFERENCES dept2(dcode)
    );

CREATE TABLE new_emp2(    -- table wihtout names of constraints. Can add contraints later
    no NUMBER(4) PRIMARY KEY,
    name VARCHAR2(20) NOT NULL,
    jumin VARCHAR2(13) NOT NULL UNIQUE,
    loc_code NUMBER(1) CHECK(loc_code < 5),
    deptno VARCHAR2(6) REFERENCES dept2(dcode)
    );

ALTER TABLE new_emp2 ADD CONSTRAINT emp2_name_uk UNIQUE(name);

-- When adding NOT NULL: "MODIFY()"
ALTER TABLE new_emp2 MODIFY (loc_code constraint emp2_loccode_nn NOT NULL);
-- Adding Foreign Key Constraint:  ...the referenced key has to be PRIMARY KEY or UNIQUE!
ALTER TABLE new_emp2 ADD CONSTRAINT emp2_no_fk FOREIGN KEY(no) REFERENCES emp2(empno);

-- Normally the parent table cannot delete the data/column that is rerefenced by a foreign key. To be able to delete it, use
-- ON DELETE CASCADE option on the parents column. It deletes the referenced child data on deletion. 
-- ON DELETE NULL option sets the referenced child data to NULL when the parent data are deleted.
CREATE TABLE c_test1( no NUMBER, name VARCHAR2(6), deptno NUMBER);
CREATE TABLE c_test2( no NUMBER, name VARCHAR2(10));

ALTER TABLE c_test2 ADD CONSTRAINT ctest2_no_uk UNIQUE(no);
ALTER TABLE c_test1 ADD CONSTRAINT ctest1_deptno_fk FOREIGN KEY(deptno) REFERENCES c_test2(no);
-- Deleting the constraint: ALTER TABLE, DROP
ALTER TABLE c_test1 DROP CONSTRAINT ctest1_deptno_fk;
ALTER TABLE c_test1 ADD CONSTRAINT ctest1_deptno_fk FOREIGN KEY(deptno) REFERENCES c_test2(no) ON DELETE CASCADE;

INSERT INTO c_test2 VALUES(10, 'AAAA');
INSERT INTO c_test2 VALUES(20, 'BBBB');
INSERT INTO c_test2 VALUES(30, 'CCCC');
COMMIT;
SELECT * FROM c_test2;
INSERT INTO c_test1 VALUES(1, 'APPLE', 10);
INSERT INTO c_test1 VALUES(2, 'BANANA', 20);
INSERT INTO c_test1 VALUES(3, 'CHERRY', 30);
INSERT INTO c_test1 VALUES(4, 'PEACH', 40);   -- Error. "Parent key not found"
SELECT * FROM c_test1;
DELETE FROM c_test2 WHERE no = 10;  -- Deleting parent data on c_test2 table. Child data on c_test1 is also deleted.

ALTER TABLE c_test1 DROP CONSTRAINT ctest1_deptno_fk;
ALTER TABLE c_test1 ADD CONSTRAINT ctest1_deptno_fk FOREIGN KEY(deptno) REFERENCES c_test2(no) ON DELETE SET NULL;
DELETE FROM c_test2 WHERE no = 20;  -- Delte parent data, child daga sets to NULL
                                    -- If the colum in child table is set to NOT NULL, this deletion cannot be done. 
ALTER TABLE c_test1 MODIFY(deptno CONSTRAINT ctest1_deptno_nn NOT NULL);  -- gets Error because there is NULL value in the col.

-- ENABLE/DISABLE the constraints
--
--- 1) DISABLE option: NOVALIDATE (DISABLE default) and VALIDATE
---- 1-1. DISABLE NOVALIDATE : disable constraint completely. Can insert/update/delete data.
INSERT INTO t_novalidate VALUES(1, 'DDD');  -- Error: "unique constraint (JAVA00.SYS_C007130) violated"
ALTER TABLE t_novalidate DISABLE NOVALIDATE CONSTRAINT SYS_C007130;   -- Notice using CONSTRAINT_NAME (SYS_C007130) above.
INSERT INTO t_novalidate VALUES(1, 'DDD'); -- not it works

---- 1-2. DISABLE VALIDATE : Cannot change data on the subject column! (wonder what the purpose of this option is)
INSERT INTO t_novalidate VALUES(4, NULL);  -- Error: "canot insert NULL" -- Name column has NOT NULL constraint
ALTER TABLE t_novalidate DISABLE VALIDATE CONSTRAINT SYS_C007129;  -- SYS_C007129 is the constraint name for NAME column NOT NL
INSERT INTO t_novalidate VALUES(4, NULL);  -- Still error: "No insert/update/delete on table with constraint 
                                            -- (JAVA00.SYS_C007129) disabled and validated"
--                                            
---- DISABLE option deletes UNIQUE INDEX on PRIMARY KEY and UNIQUE constraints!
--
--- 2) ENABLE -- NOVALIDATE and VALIDATE (ENABLE default)
---- 2-1. ENABLE NOVALIDATE: only enables constraints of the NEWLY incoming data. Don't check constraints before ENABLE is used
---- 2-2. ENABLE VALIDATE: enables constraints on ALL data (previous and new). Cancels ENABLE if violation is found...so one
----                        will have to individually find the data, change, and enable again...
INSERT INTO t_enable VALUES(1, 'AAA');
INSERT INTO t_enable VALUES(2, 'BBB');
INSERT INTO t_enable VALUES(3, NULL);   -- error. NOT NULL constraint is set on the column
ALTER TABLE t_enable DISABLE CONSTRAINT te_name_nn;  -- DISABLE the constraint (DISABLE NOVALIDATE is default)
INSERT INTO t_enable VALUES(3, NULL);   -- now can insert NULL

ALTER TABLE t_enable ENABLE NOVALIDATE CONSTRAINT te_name_nn;  -- now ENABLE the constraint, but the table HAS null data.
SELECT * FROM t_enable;   -- the table HAS null data despite the NOT NULL constraint because NOVALIDATE doesn't check the old d
INSERT INTO t_enable VALUES(3, NULL);  -- Can't.

ALTER TABLE t_enable DISABLE CONSTRAINT te_name_nn; 
ALTER TABLE t_enable ENABLE VALIDATE CONSTRAINT te_name_nn; -- Error due to the previous NULL data. "check constraint violated" 
--- Use EXCEPTION table to fix the troubled data on the way to execute ENABLE option.
--- Use SYS account and create EXCEPTION TABLE (@?/rdbms/admin/utlexcpt.sql)
CREATE TABLE java00.tt500( no NUMBER CONSTRAINT tt500_ck CHECK( no > 5) );
ALTER TABLE java00.tt500 DISABLE CONSTRAINT tt500_ck;
INSERT INTO java00.tt500 VALUES(1);
INSERT INTO java00.tt500 VALUES(6);
INSERT INTO java00.tt500 VALUES(7);
COMMIT;
SELECT * FROM java00.tt500;

-- Now ENABLE VALIDATE the constraint and put the violating data into exception table
--ALTER TABLE java00.tt500 ENABLE VALIDATE CONSTRAINT tt500_ck EXCEPTIONS INTO sys.exceptions; 
CREATE TABLE exceptions( row_id ROWID, owner VARCHAR2(30), table_name VARCHAR2(30), constraint VARCHAR2(30));
ALTER TABLE java00.tt500 ENABLE VALIDATE CONSTRAINT tt500_ck EXCEPTIONS INTO exceptions;  
    -- Above: "cannot validate...CHECK constraint violated"
SELECT rowid, no FROM java00.tt500 WHERE rowid in (SELECT row_id FROM exceptions); -- ROW_ID: AAAE/FAABAAALWpAAA, NO = 1
UPDATE java00.tt500 SET no = 8 WHERE rowid = AAAE/FAABAAALWpAAA; -- ORA-00904: "FAABAAALWPAAA": invalid identifier
UPDATE java00.tt500 SET no = 8 WHERE no = 1;
COMMIT;
TRUNCATE TABLE exceptions;  -- Now that the errored row is updated, truncate the error log
select * from exceptions;
select rowid, no from java00.tt500;
ALTER TABLE java00.tt500 ENABLE VALIDATE CONSTRAINT tt500_ck EXCEPTIONS INTO exceptions;  -- Now ENABLE VALIDATE option works.


-- View the constraints on USER_CONSTRAINTS dictionary and USER_CONS_COLUMNS dictionary
-- (Note: table name has to be CAPITAL)
SELECT * FROM user_constraints WHERE table_name = 'T_NOVALIDATE'; -- CONSTRAINT_TYPE: C - Check, P - Primary Key, U - Unique
SELECT * FROM user_cons_columns WHERE table_name = 'T_NOVALIDATE';

----
---- CHAPTER 8. INDEX
----
-- 1) UNIQUE INDEX
CREATE UNIQUE INDEX IDX_DEPT2_DNAME ON dept2(dname);
-- 2) NON-UNIQUE INDEX
CREATE INDEX IDX_DEPT2_AREA ON dept2(area);

-- Functon Based Index(FBI)
CREATE INDEX idx_prof_fbi ON professor(pay + 100);   -- makes a new column(pay + 100) on Professor table
-- Descending Index
CREATE INDEX idx_prof_pay ON professor(pay DESC);
-- Composite Index  -- where creating index combining two or more columns
CREATE INDEX idx_emp_comp ON emp( ename, job);

-- View created indexes
SELECT table_name, column_name, index_name FROM USER_IND_COLUMNS;  -- or DBA_IND_COLUMNS
SELECT * FROM USER_INDEXES; -- OR DBA_INDEXES

-- Monitoring indexes
ALTER INDEX IDX_DEPT2_DNAME MONITORING USAGE;
ALTER INDEX IDX_DEPT2_DNAME NOMONITORING USAGE; -- monitoring off
-- check
SELECT index_name, used FROM v$object_usage WHERE index_name = 'IDX_DEPT2_DNAME';
select * from v$object_usage;

-- Index Rebuild
DROP TABLE inx_test;
CREATE TABLE inx_test (no NUMBER); -- creating table
BEGIN FOR i IN 1..10000 LOOP        -- inserting data
        INSERT INTO inx_test VALUES(i);
      END LOOP;
     COMMIT;
     END;
/
CREATE INDEX idx_inxtest_no ON inx_test(no);   -- creating index

ANALYZE INDEX idx_inxtest_no VALIDATE STRUCTURE; -- analyze the index
SELECT (del_lf_rows_len / lf_rows_len) * 100 BALANCE 
    FROM index_stats 
    WHERE name = 'IDX_INXTEST_NO';    -- BALANCE shows 0. 0 is good.
    
---- Now delete 4000 data out of 10000
DELETE FROM inx_test WHERE no BETWEEN 1 AND 4000;
SELECT COUNT(*) FROM inx_test;
SELECT (del_lf_rows_len / lf_rows_len) * 100 BALANCE 
    FROM index_stats 
    WHERE name = 'IDX_INXTEST_NO';   -- Balance is still 0
ANALYZE INDEX idx_inxtest_no VALIDATE STRUCTURE;  -- analyze the index again
SELECT (del_lf_rows_len / lf_rows_len) * 100 BALANCE 
    FROM index_stats 
    WHERE name = 'IDX_INXTEST_NO';  -- now balance is 39.960347.., meaning about 40% is out of balance

---- Now rebuild the index
ALTER INDEX idx_inxtest_no REBUILD; 

ANALYZE INDEX idx_inxtest_no VALIDATE STRUCTURE;  -- analyze the index again
SELECT (del_lf_rows_len / lf_rows_len) * 100 BALANCE 
    FROM index_stats 
    WHERE name = 'IDX_INXTEST_NO';    -- Balance is now 0.
    
----
---- CHAPTER 9. VIEW
----
----- VIEW does not contain data. It only executes sub queries upon SELECT operation. 
----- The sub queries fetch data from tables, returns to the user, then delete the fetched.
CREATE OR REPLACE VIEW v_emp1 
    AS SELECT empno, ename, hiredate
       FROM emp;
SELECT * FROM v_emp1;

-- other VIEW examples
CREATE VIEW prof_view AS SELECT name, deptno, pay FROM professor;
CREATE TABLE o_table (a NUMBER, b NUMBER);
CREATE VIEW view1 
    AS SELECT a, b FROM o_table;    
CREATE VIEW view2 
    AS SELECT a, b FROM o_table 
    WITH READ ONLY;
INSERT INTO view1 VALUES(3,9);   -- inserting data using VIEW is possible
INSERT INTO view1 VALUES(5,6);

select * from view1;
SELECT * FROM o_table;  -- Notice inserted value using VIEW also inserted into o_table 

CREATE VIEW view3 
    AS SELECT a, b FROM o_table
    WHERE a = 3
    WITH CHECK OPTION;   -- cannot do "UPDATE view3 SET a = 5" due to the CHECK OPTION on a
DELETE FROM view3 WHERE a = 3;   -- BUT you can DELETE it!!   
 
-- COMPLEX VIEW
--- View which contains joining of tables
CREATE OR REPLACE VIEW v_emp AS
    SELECT e.ename, d.dname FROM emp e, dept d WHERE e.deptno = d.deptno;  --- Doesn't execute the sub queries
SELECT * from v_emp;   --- the sub-queries are executed now

-- INLINE VIEW
--- Write sub queries in the FROM clause so that one doesn't have to create view
SELECT e.deptno, d.dname, e.sal 
    FROM (SELECT deptno, MAX(sal) sal FROM emp GROUP BY deptno) e, dept d   -- this SELECT clause is the INLINE VIEW query
    WHERE e.deptno = d.deptno;

-- CHECK the created VIEW
SELECT view_name, text, read_only FROM USER_VIEWS;  -- or DBA_VIEWS if you're SYSDBA

-- MATERIALIZED VIEW (MVIEW)
--- Normally VIEW does not contain data but MVIEW does. It increases efficiency when a certain (large) dataset is viewed 
--- often by (large number of) users.
--- Requires QUERY REWRITE and CREATE MATERIALIZED VIEW grant.

CREATE MATERIALIZED VIEW m_prof  -- Oracle Database Express Edition does not contain MATERIALIZED VIEW QUERY REWRITE feature
    BUILD IMMEDIATE  
    REFRESH    -- When the data on original table has changed 
    ON DEMAND  -- ON DEMAND -- the user does refresh by hand, ON COMMIT -- done at the time of COMMIT
    COMPLETE   -- COMPLETE/FAST/FORCE/NEVER
    ENABLE QUERY REWRITE
    AS
        SELECT profno, name, pay 
        FROM professor;

BEGIN
    DBMS_MVIEW.REFRESH('M_PROF');     -- Refresh by hand
    END;
/

EXEC DBMS_MVIEW.REFRESH_ALL_MVIEWS;  -- Can also do this.

-- View or Drop the MVIEW
SELECT * FROM USER_MVIEWS;  -- or DBA_MVIEWS
DROP MATERIALIZED VIEW m_prof;

---------- CH 9 EXERCISE (p.432~434) ----------
-- 1. 
CREATE VIEW v_prof_dept2 
    AS SELECT p.profno, p.name, d.dname
    FROM professor p, department d
    WHERE p.deptno = d.deptno;
SELECT * FROM v_prof_dept2;    

-- 2.
SELECT d.dname, a.MAX_HEIGHT, a.MAX_WEIGHT 
    FROM department d, 
         (SELECT deptno1, MAX(height) "MAX_HEIGHT", MAX(weight) "MAX_WEIGHT" FROM student GROUP BY deptno1) a
    WHERE a.deptno1 = d.deptno;

-- 3.
SELECT d.dname, a.MAX_HEIGHT, a.name, a.height 
    FROM department d,
         (SELECT deptno1, name, height, MAX(height) OVER(PARTITION BY deptno1) "MAX_HEIGHT"  FROM student) a
    WHERE a.deptno1 = d.deptno
    AND a.MAX_HEIGHT = a.height;
    
-- 4.
SELECT a.grade, a.name, a.height, a.AVG_HEIGHT
    FROM (SELECT name, grade, height, AVG(height) OVER (PARTITION BY grade) "AVG_HEIGHT" FROM student) a
    WHERE a.height > a.avg_height
    ORDER BY grade ASC;

-- 5.
-- 6.