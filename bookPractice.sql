-- CH.3 "������ �Լ�(�׷��Լ�)"

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

-- PIVOT �Լ��� ������� �ʰ� �޷� �����
select max(decode(day, 'SUN', dayno)) SUN,
    max(decode(day, 'MON', dayno)) MON,
    max(decode(day, 'TUE', dayno)) TUE,
    max(decode(day, 'WED', dayno)) WED,
    max(decode(day, 'THU', dayno)) THU,
    max(decode(day, 'FRI', dayno)) FRI,
    max(decode(day, 'SAT', dayno)) SAT
    from cal group by weekno order by weekno;
    
-- PIVOT �Լ��� ����Ͽ� �޷� �����
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

-- EMP���̺��� �μ����� �� ���޺� �ο��� �� ������ ����ϱ� (PIVT() �Լ����)
SELECT * FROM (SELECT deptno, job, empno FROM EMP)
    PIVOT( COUNT(empno) FOR job IN ('CLERK' AS "CLERK",
                                    'MANAGER' AS "MANAGER",
                                    'PRESIDENT' AS "PRESIDENT",
                                    'ANALYST' AS "ANALYST",
                                    'SALESMAN' AS "SALESMAN")
          )
    ORDER BY deptno;

-- UNPIVOT()�Լ� TEST
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

-- RANK() �Լ� �̿뿹
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

-- DENSE_RANK() : RANK�� �ϵ� ������ ������ �ϳ��� �Ǽ��� ����ϹǷ� ���ӵ� ������ �����ش�
SELECT empno, ename, sal, 
    RANK() OVER (ORDER BY sal DESC) sal_rank, 
    DENSE_RANK() OVER (ORDER BY sal DESC) sal_dense_rank
FROM emp;

-- ROW_NUMBER(): RANK()�� DENSE_RANK()�� ������ ���� ���� ������ �ο������� ROW_NUMBER()�� 
-- ������ ���̶� ������ ������ �ο��Ѵ�.
SELECT empno, ename, sal, 
    RANK() OVER (ORDER BY sal DESC) sal_rank, 
    DENSE_RANK() OVER (ORDER BY sal DESC) sal_dense_rank,
    ROW_NUMBER() OVER (ORDER BY sal DESC) sal_row_num
FROM emp;

-- SUM() OVER: �����հ� ���Ҷ� �̿�. �̿� ��
SELECT p_date, p_code, p_qty, p_total, SUM(p_total) OVER (ORDER BY p_total) "TOTAL"
FROM panmae WHERE p_store = 1000;

SELECT p_date, p_code, p_qty, p_total, SUM(p_total) OVER (PARTITION BY p_code ORDER BY p_total) "TOTAL"
FROM panmae WHERE p_store = 1000;

SELECT p_code, p_store, p_date, p_qty, p_total, 
    SUM(p_total) OVER (PARTITION BY p_code, p_store ORDER BY p_total) "TOTAL"
FROM panmae;

-- RATIO_TO_REPORT() �Լ��̿��� �Ǹź��� ���ϱ�
-- panmae TABLE���� 100�� ��ǰ�� �Ǹ� ������ �� �Ǹ������� �Ǹ� ������ ���غ���

SELECT p_code, SUM(SUM(p_qty)) OVER() "TOTAL_QTY",
               SUM(SUM(p_total)) OVER() "TOTAL_PRICE", p_store, p_qty, p_total,
               ROUND( (RATIO_TO_REPORT(SUM(p_qty)) OVER()) *100, 2) "QTY_%",
               ROUND( (RATIO_TO_REPORT(SUM(p_total)) OVER()) *100, 2) "TOTAL_%"
FROM panmae WHERE p_code = 100 
GROUP BY p_code, p_store, p_qty, p_total;

-- LAG() �Լ��� �̿��� ����
-- 1) 1000�� �Ǹ����� ���ں� �Ǹ� ������ �ݾ� �� ���� �Ǹ� ������ �ݾ����� ���
SELECT p_store, p_date, p_code, p_qty, 
    LAG(p_qty, 1) OVER (ORDER BY p_date) "D-1 QTY",
    p_qty - LAG(p_qty, 1) OVER (ORDER BY p_date) "DIFF QTY",
    p_total,
    LAG(p_total, 1) OVER (ORDER BY p_date) "D-1 PRICE",
    p_total - LAG(p_total, 1) OVER (ORDER BY p_date) "DIFF PRICE"
FROM panmae WHERE p_store = 1000; 
-- 2) ��� �Ǹ��� ���� �� ���
SELECT p_store, p_date, p_code, p_qty, 
    LAG(p_qty, 1) OVER (PARTITION BY p_store ORDER BY p_date) "D-1 QTY",
    p_qty - LAG(p_qty, 1) OVER (PARTITION BY p_store ORDER BY p_date) "DIFF QTY",
    p_total,
    LAG(p_total, 1) OVER (PARTITION BY p_store ORDER BY p_date) "D-1 PRICE",
    p_total - LAG(p_total, 1) OVER (PARTITION BY p_store ORDER BY p_date) "DIFF PRICE"
FROM panmae; 

-- P.213 �������� 
--
-- 1.
SELECT MAX(SUM(NVL(sal,0) + NVL(comm,0))) "MAX", 
       MIN(SUM(NVL(sal,0) + NVL(comm,0))) "MIN",
       TO_CHAR(AVG(SUM(NVL(sal,0) + NVL(comm,0))), '9999.9') "AVG"
FROM emp GROUP BY empno ;

-- 2.
SELECT 
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
       --TO BE CONTINUED       
FROM student;

SELECT birthday FROM student;

