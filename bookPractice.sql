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