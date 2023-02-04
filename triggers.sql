-- Author: Mikołaj Paszkowski 292764

-- COMMENT this triggers are written based on an updated version of a database
--  whose sql scripts for ddl and population are attached to the project (db_population_edaba.sql, db_ddl_edaba.sql)
--  HOWEVER in galera server on my assigned database MPASZKOW these changes are already applied
--  no need to fire them again


-- *****    TRIGGER 1   ******
-- this trigger validate the values of the INSERT statement. At the beginning it logs the information
-- about the insert attempt, then there are performed checks such as:
--      - percent value (<= 100, percent_value = 100% only for events with free gifts) and amount cannot both be smaller or equal 0
--      - discount type and description must by longer than 2 characters
--      - start date cannot be after end date
--      - automatic completition of  modified_at to the current time
CREATE OR REPLACE TRIGGER validate_discounts_insert
    BEFORE INSERT
        OR UPDATE
    ON DISCOUNT
    FOR EACH ROW
BEGIN

    IF :NEW.PERCENT_VALUE > 100 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Discount percent_value cannot be greater than 100');
    END IF;

    IF (:NEW.AMOUNT <= 0 OR :NEW.AMOUNT IS NULL) AND (:NEW.PERCENT_VALUE <= 0 OR :NEW.PERCENT_VALUE IS NULL) THEN
        RAISE_APPLICATION_ERROR(-20002, 'Discount must have a non-zero, positive value for amount or percent_value');
    END IF;

    IF LENGTH(:NEW.DISCOUNT_TYPE) < 3 OR LENGTH(:NEW.DESCRIPTION) < 3 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Discount type and description characters length cannot be less than 3');
    END IF;

    IF :NEW.START_ON >= :NEW.ENDS_ON THEN
        RAISE_APPLICATION_ERROR(-20004, 'Discount starting date cannot be after or on the same day as ending date');
    end if;

    :NEW.MODIFIED_AT := SYSDATE;
END;


-- TESTS

-- should throw an error message when trying to insert discount with negative amount
INSERT INTO DISCOUNT (DISCOUNT_ID, DESCRIPTION, DISCOUNT_TYPE, PERCENT_VALUE, AMOUNT, STATUS, START_ON, ENDS_ON)
VALUES (123, 'SOME DESCRIPTION', 'OTHER', 0, -123, 'ACTIVE', SYSDATE, SYSDATE + 5);

-- should throw an error message when trying to insert discount with negative percent value
INSERT INTO DISCOUNT (DISCOUNT_ID, DESCRIPTION, DISCOUNT_TYPE, PERCENT_VALUE, AMOUNT, STATUS, START_ON, ENDS_ON)
VALUES (123, 'SOME DESCRIPTION', 'OTHER', -12, 0, 'ACTIVE', SYSDATE, SYSDATE + 5);

-- should throw an error message when trying to insert discount with no amount AND percent val
INSERT INTO DISCOUNT (DISCOUNT_ID, DESCRIPTION, DISCOUNT_TYPE, PERCENT_VALUE, AMOUNT, STATUS, START_ON, ENDS_ON)
VALUES (123, 'SOME DESCRIPTION', 'OTHER', null, null, 'ACTIVE', SYSDATE, SYSDATE + 5);

-- should throw an error message when trying to insert discount with BOTH 0 amount AND percent val
INSERT INTO DISCOUNT (DISCOUNT_ID, DESCRIPTION, DISCOUNT_TYPE, PERCENT_VALUE, AMOUNT, STATUS, START_ON, ENDS_ON)
VALUES (123, 'SOME DESCRIPTION', 'OTHER', 0, 0, 'ACTIVE', SYSDATE, SYSDATE + 5);

-- cannot insert discount with start date after end date
INSERT INTO DISCOUNT (DISCOUNT_ID, DESCRIPTION, DISCOUNT_TYPE, PERCENT_VALUE, AMOUNT, STATUS, START_ON, ENDS_ON)
VALUES (123, 'SOME DESCRIPTION', 'OTHER', 0, 123, 'INACTIVE', SYSDATE + 5, SYSDATE);

-- after update set modified_at date to the current one

--     PREVIOUS STATE
SELECT *
FROM DISCOUNT
WHERE DISCOUNT_ID = 1;
-- CHANGE
UPDATE DISCOUNT
SET DISCOUNT_TYPE = 'OTHER'
WHERE DISCOUNT_ID = 1;
-- RESULT
SELECT *
FROM DISCOUNT
WHERE DISCOUNT_ID = 1;
-- ROLLBACK
UPDATE DISCOUNT
SET DISCOUNT_TYPE = 'Temporary'
WHERE DISCOUNT_ID = 1;


-- cannot update description to the string of character length less than 3

--     CURRENT STATE
SELECT *
FROM DISCOUNT
WHERE DISCOUNT_ID = 1;
-- CHANGE
UPDATE DISCOUNT
SET DESCRIPTION = 'XX'
WHERE DISCOUNT_ID = 1;
-- RESULT
-- -20003 error thrown

-- cannot update percent_value to bigger or equal than 100

--     CURRENT STATE
SELECT *
FROM DISCOUNT
WHERE DISCOUNT_ID = 1;
-- CHANGE
UPDATE DISCOUNT
SET PERCENT_VALUE = 123
WHERE DISCOUNT_ID = 1;
-- RESULT
-- -20001 error thrown


-- ******   TRIGGER 2    ******

-- this trigger will be responsible for logging the messages related to changes of statuses of orders
-- where there is a change in STATUS or TOTAL_AMOUNT then it will create a log record with related message
-- and all necessary info, if no change occurred in specific fields it will save a message that there was no update
-- It uses the newly created table called ORDER_LOG to store such logs

CREATE OR REPLACE TRIGGER order_logging_trigger
    AFTER UPDATE OF STATUS, TOTAL_AMOUNT
    ON "Order"
    FOR EACH ROW
DECLARE
    message varchar2(150);
BEGIN
    IF :OLD.STATUS != :NEW.STATUS THEN
        message := 'Order: ' || :NEW.ORDER_ID || ' changed status to: ' || :NEW.STATUS;
    ELSIF :OLD.TOTAL_AMOUNT != :NEW.TOTAL_AMOUNT THEN
        message := 'Order: ' || :NEW.ORDER_ID || ' changed total amount to: ' || :NEW.TOTAL_AMOUNT;
    ELSE
        message := 'Order: ' || :NEW.ORDER_ID || ' was updated without a change';
    END IF;
    INSERT INTO ORDER_LOG (ORDER_ID, STATUS, MSG, REPORTED)
    VALUES (:NEW.ORDER_ID, :NEW.STATUS, message, SYSDATE);
end;

-- TESTS

-- should create order_log record when order has changed status  (fire in sequence with rollback)

-- before order_log is empty
SELECT *
FROM ORDER_LOG;
-- before order status is IN_PROCESS and has total_amount = 19020
SELECT *
FROM "Order"
WHERE ORDER_ID = 1;

-- when update to DISPATCHED
UPDATE "Order"
SET STATUS = 'DISPATCHED'
WHERE ORDER_ID = 1;

-- the record of order_log should be created
select *
from ORDER_LOG;

-- when update of TOTAL_AMOUNT
UPDATE "Order"
SET TOTAL_AMOUNT = 3000
WHERE ORDER_ID = 1;

-- the next log should be generated
select *
from ORDER_LOG;

-- rollback
UPDATE "Order"
SET STATUS = 'IN_PROCESS'
WHERE ORDER_ID = 2;

UPDATE "Order"
SET TOTAL_AMOUNT = 19020
WHERE ORDER_ID = 2;


-- ****** TRIGGER 3 ******

-- This trigger will handle the updating the order status depending on the status of the corresponding
-- payment details only if the change was not performed from PAID status (if PAID, we cannot revert it (business rules)) while
--      * PAID should change the order status to IN_PREPARATION as well
--      * IN_PROGRESS should change the status of the order to IN_PROCESS
--      * UNPAID should change the order status to AWAITING_PAYMENT


CREATE OR REPLACE TRIGGER update_order_status_trigger
    AFTER INSERT OR UPDATE OF STATUS
    ON PAYMENTDETAILS
    FOR EACH ROW
    WHEN ( OLD.STATUS != 'PAID')
DECLARE
    new_status VARCHAR2(15 char);
BEGIN
    IF :NEW.STATUS = 'PAID' THEN
        new_status := 'IN_PREPARATION';
    ELSIF :NEW.STATUS = 'IN_PROGRESS' THEN
        new_status := 'IN_PROCESS';
    ELSIF :NEW.STATUS = 'UNPAID' THEN
        new_Status := 'AWAIT_PAYMENT';
    ELSE
        new_Status := 'BLOCKED';
    END IF;

    UPDATE "Order" order1
    SET STATUS = new_status
    WHERE :NEW.PAYMENT_DET_ID = order1.PAYMENT_DET_ID;
end;

--    TESTS
-- 1. should change ORDER status from BLOCKED TO AWAIT_PAYMENT
-- before -> the order is in BLOCKED status
SELECT *
FROM "Order"
WHERE ORDER_ID = 5;
-- AND PAYMENT DETAILS is in UNKNOWN status
select *
from PAYMENTDETAILS
where PAYMENT_DET_ID = (select PAYMENT_DET_ID
                        from "Order"
                        where "Order".PAYMENT_DET_ID = PAYMENTDETAILS.PAYMENT_DET_ID
                          AND "Order".PAYMENT_DET_ID = 246);


-- when payment details status changed to UNPAID
UPDATE PAYMENTDETAILS det
SET det.STATUS = 'UNPAID'
WHERE PAYMENT_DET_ID = 246;

-- after -> the order is in AWAIT_PAYMENT
SELECT *
FROM "Order"
WHERE ORDER_ID = 5;
-- AND PAYMENT DETAILS is status PAID
select *
from PAYMENTDETAILS
where PAYMENT_DET_ID = 246;

-- ROLLBACK
UPDATE PAYMENTDETAILS det
SET det.STATUS = 'UNKNOWN'
WHERE PAYMENT_DET_ID = 246;



-- 2. should change the status of order if related payment details status changed
-- before -> the order is in BLOCKED status
SELECT *
FROM "Order"
WHERE ORDER_ID = 5;
-- AND PAYMENT DETAILS in_progress
select *
from PAYMENTDETAILS
where PAYMENT_DET_ID = (select PAYMENT_DET_ID
                        from "Order"
                        where "Order".PAYMENT_DET_ID = PAYMENTDETAILS.PAYMENT_DET_ID
                          AND "Order".PAYMENT_DET_ID = 246);


-- when payment details status changed to PAID
UPDATE PAYMENTDETAILS det
SET det.STATUS = 'PAID'
WHERE PAYMENT_DET_ID = 246;

-- after -> the order is in IN_PREPARATION
SELECT *
FROM "Order"
WHERE ORDER_ID = 5;
-- AND PAYMENT DETAILS is status PAID
select *
from PAYMENTDETAILS
where PAYMENT_DET_ID = 246;
-- ROLLBACK
UPDATE PAYMENTDETAILS det
SET det.STATUS = 'UNKNOWN'
WHERE PAYMENT_DET_ID = 246;
