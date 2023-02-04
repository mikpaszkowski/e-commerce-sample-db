-- DISCOUNT TABLE

DECLARE
    i                   INTEGER      := 1;
     v_start_on          TIMESTAMP;
    v_ends_on           TIMESTAMP;
    v_percent_value_val INTEGER;
    v_amount_val        INTEGER;
    v_discount_type_val VARCHAR2(15) := 'OTHER';
    v_status_val        VARCHAR2(15) := 'OTHER';
    v_description_val   VARCHAR2(30) := 'OTHER';
BEGIN
    -- Start the transaction
    FOR i IN 1..10
        LOOP
            IF MOD(i, 2) = 0 THEN
                v_percent_value_val := FLOOR(DBMS_RANDOM.value(1, 99));
                v_amount_val := NULL;
            ELSE
                v_percent_value_val := NULL;
                v_amount_val := FLOOR(DBMS_RANDOM.value(100, 500));
            END IF;
            v_start_on := SYSDATE + FLOOR(DBMS_RANDOM.VALUE(1, 365));
            v_ends_on := v_start_on + FLOOR(DBMS_RANDOM.VALUE(1, 365));
            INSERT INTO discount (DISCOUNT_ID, DESCRIPTION, DISCOUNT_TYPE, PERCENT_VALUE, AMOUNT, STATUS, START_ON, ENDS_ON)
            VALUES (i, v_description_val, v_discount_type_val, v_percent_value_val, v_amount_val, v_status_val,
                    v_start_on, v_ends_on);
        END LOOP;

    -- START OF UPDATE OF RECORDS TO ADJUST THE MEANINGFUL COLUMN VALUES

    UPDATE DISCOUNT
    SET DESCRIPTION   = 'New Year Discount',
        DISCOUNT_TYPE = 'Temporary',
        STATUS        = 'ACTIVE'
    WHERE DISCOUNT_ID = 1;

    UPDATE DISCOUNT
    SET DESCRIPTION   = 'Summer Sale',
        DISCOUNT_TYPE = 'Temporary',
        STATUS        = 'ACTIVE'
    WHERE DISCOUNT_ID = 2;

    UPDATE DISCOUNT
    SET DESCRIPTION   = 'Black Friday Deal',
        DISCOUNT_TYPE = 'Temporary',
        STATUS        = 'ACTIVE'
    WHERE DISCOUNT_ID = 3;

    UPDATE DISCOUNT
    SET DESCRIPTION   = 'Limited Time Offer',
        DISCOUNT_TYPE = 'Temporary',
        STATUS        = 'ACTIVE'
    WHERE DISCOUNT_ID = 4;

    UPDATE DISCOUNT
    SET DESCRIPTION   = 'Early Bird Special',
        DISCOUNT_TYPE = 'Temporary',
        STATUS        = 'ACTIVE'
    WHERE DISCOUNT_ID = 5;

    UPDATE DISCOUNT
    SET DESCRIPTION   = 'Discount for new customers',
        DISCOUNT_TYPE = 'First-time',
        STATUS        = 'INACTIVE'
    WHERE DISCOUNT_ID = 6;

    UPDATE DISCOUNT
    SET DESCRIPTION   = 'Discount for orders over $50',
        DISCOUNT_TYPE = 'Order total',
        STATUS        = 'INACTIVE'
    WHERE DISCOUNT_ID = 7;

    UPDATE DISCOUNT
    SET DESCRIPTION   = 'Discount for referring friends',
        DISCOUNT_TYPE = 'Loyalty',
        STATUS        = 'INACTIVE'
    WHERE DISCOUNT_ID = 8;

    UPDATE DISCOUNT
    SET DESCRIPTION   = 'Discount for sub. email lists',
        DISCOUNT_TYPE = 'Order total',
        STATUS        = 'INACTIVE'
    WHERE DISCOUNT_ID = 9;

    UPDATE DISCOUNT
    SET DESCRIPTION   = 'Discount for orders over $100',
        DISCOUNT_TYPE = 'Category',
        STATUS        = 'INACTIVE'
    WHERE DISCOUNT_ID = 10;
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
END ;

-- USER TABLE

DECLARE
    v_user_id           VARCHAR2(20);
    v_created_date_user TIMESTAMP;
    v_password          VARCHAR2(60);
BEGIN
    FOR i IN 1..25
        LOOP
            v_user_id := DBMS_RANDOM.string('X', 10);
            v_password := DBMS_RANDOM.string('X', 20);
            v_created_date_user := SYSDATE - FLOOR(DBMS_RANDOM.value(1, 365));
            INSERT INTO "User" (USER_ID, PASSWD, CREATED_AT, MODIFIED_AT)
            VALUES (v_user_id, v_password, v_created_date_user, SYSDATE);
        END LOOP;
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
END;


-- PAYMENT TABLE

DECLARE
    v_pay_type    VARCHAR2(15);
    v_account_num VARCHAR2(25);
    v_card_number VARCHAR2(19);
    v_cc_exp_date VARCHAR2(14);
    v_cc_code     VARCHAR2(4);
    v_user_id     VARCHAR2(20);
    v_count       NUMBER;
BEGIN
    v_count := 1;

    FOR i IN (SELECT ROWNUM row_num, "User".*
              FROM "User"
              ORDER BY USER_ID DESC)
        LOOP
            v_user_id := i.user_id;
            CASE FLOOR(DBMS_RANDOM.value(1, 5))
                WHEN 1 THEN v_pay_type := 'BANK_ACCOUNT';
                            v_account_num := REGEXP_REPLACE(DBMS_RANDOM.STRING('X', 20), '[^0-9]', '');
                            v_cc_exp_date := NULL;
                            v_cc_code := NULL;
                            v_card_number := NULL;
                WHEN 2 THEN v_pay_type := 'CREDIT_CARD';
                            v_cc_exp_date := to_char(trunc(SYSDATE + DBMS_RANDOM.VALUE(10, 365)), 'YYYY-MM-DD');
                            v_card_number := REGEXP_REPLACE(DBMS_RANDOM.STRING('X', 20), '[^0-9]', '');
                            v_cc_code := REGEXP_REPLACE(DBMS_RANDOM.STRING('X', 4), '[^0-9]', '');
                            v_account_num := NULL;
                WHEN 3 THEN v_pay_type := 'DEBIT_CARD';
                            v_account_num := NULL;
                            v_card_number := REGEXP_REPLACE(DBMS_RANDOM.STRING('X', 20), '[^0-9]', '');
                            v_cc_exp_date := to_char(trunc(SYSDATE + DBMS_RANDOM.VALUE(10, 365)), 'YYYY-MM-DD');
                            v_cc_code := REGEXP_REPLACE(DBMS_RANDOM.STRING('X', 3), '[^0-9]', '');
                WHEN 4 THEN v_pay_type := 'PAYPAL';
                            v_card_number := NULL;
                            v_account_num := NULL;
                            v_cc_exp_date := NULL;
                            v_cc_code := NULL;
                END CASE;
            INSERT INTO PAYMENT (PAYMENT_ID, PAY_TYPE, ACCOUNT_NUM, CARD_NUMBER, CC_EXP_DATE, CC_CODE, CREATED_AT,
                                 MODIFIED_AT, USER_ID)
            VALUES (v_count, v_pay_type, v_account_num, v_card_number, v_cc_exp_date, v_cc_code,
                    SYSDATE - FLOOR(DBMS_RANDOM.VALUE(1, 365)), SYSDATE, v_user_id);
            v_count := v_count + 1;
        END LOOP;
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
END;

-- PRODUCT TABLE

DECLARE
    i                 INTEGER           := 1;
    v_price_val       NUMBER;
    v_description_val VARCHAR2(50 char) := 'NO DESCRIPTION';
    v_category_val    VARCHAR2(15 char) := 'NO CATEGORY';
    v_created         TIMESTAMP;

BEGIN

    FOR i IN 1..200
        LOOP
            v_price_val := FLOOR(DBMS_RANDOM.VALUE(1, 15) * 100);
            v_description_val := 'Product ' || i;
            v_category_val := 'Category ' || trunc(DBMS_RANDOM.VALUE(1, 10));
            v_created := SYSDATE - FLOOR(DBMS_RANDOM.VALUE(1, 365));
            INSERT INTO product (PRODUCT_ID, PRICE, DESCRIPTION, CATEGORY, CREATED_AT, UPPDATED_AT)
            VALUES (i, v_price_val, v_description_val, v_category_val, v_created, SYSDATE);
        end loop;
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
end;

-- ORDER TABLE - initial orders
DECLARE
    v_status   VARCHAR2(15);
    v_order_id NUMBER := 1;
BEGIN
    v_order_id := 1;
    FOR i IN (SELECT ROWNUM row_num, "User".*
              FROM "User"
              ORDER BY USER_ID DESC)
        LOOP
            FOR j IN 1..10
                LOOP
                    CASE FLOOR(DBMS_RANDOM.VALUE(1, 6))
                        WHEN 1 THEN v_status := 'DELIVERED';
                        WHEN 2 THEN v_status := 'IN_PROCESS';
                        WHEN 3 THEN v_status := 'DISPATCHED';
                        WHEN 4 THEN v_status := 'PAID';
                        WHEN 5 THEN v_status := 'INITIAL';
                        ELSE v_status := 'BLOCKED';
                        END CASE;

                    INSERT INTO "Order" (ORDER_ID, STATUS, TOTAL_AMOUNT, CREATED_AT, MODIFIED_AT, USER_ID,
                                         PAYMENT_DET_ID)
                    VALUES (v_order_id, v_status, NULL, SYSDATE - FLOOR(DBMS_RANDOM.VALUE(1, 365)), SYSDATE,
                            i.USER_ID,
                            NULL);
                    v_order_id := v_order_id + 1;
                end loop;

        END LOOP;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
END;

-- ORDER PRODUCTS  - relates to created initial orders

DECLARE
    v_quantity         NUMBER;
    v_product_id       NUMBER;
    v_order_product_id NUMBER;
BEGIN
    -- create order products for created orders
    v_order_product_id := 1;
    FOR i IN (SELECT ROWNUM row_num, "Order".*
              FROM "Order"
              ORDER BY ORDER_ID DESC)
        LOOP
            FOR j IN 1..3
                LOOP
                    SELECT PRODUCT_ID
                    INTO v_product_id
                    FROM PRODUCT
                    WHERE PRODUCT_ID = FLOOR(DBMS_RANDOM.VALUE(1, 100));
                    v_quantity := FLOOR(DBMS_RANDOM.VALUE(1, 10));
                    INSERT INTO ORDERPRODUCT (ORDER_PRODUCT_ID, QUANTITY, CREATED_AT, UPDATED_AT, ORDER_ID, PRODUCT_ID)
                    VALUES (v_order_product_id, v_quantity, SYSDATE - FLOOR(DBMS_RANDOM.VALUE(1, 365)), SYSDATE,
                            i.ORDER_ID,
                            v_product_id);
                    v_order_product_id := v_order_product_id + 1;
                end loop;
        END LOOP;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
END;

-- UPDATE ORDER TABLE - update orders with the total amount based on order products

DECLARE
    v_order_total NUMBER(10, 2);
BEGIN
    EXECUTE IMMEDIATE 'alter table "Order" drop constraint order_paymentdetails_fk';
    EXECUTE IMMEDIATE 'alter table PAYMENTDETAILS drop constraint paymentdetails_order_fk';

    FOR i IN (SELECT "Order".*
              FROM "Order")
        LOOP
            SELECT SUM(ORDERPRODUCT.QUANTITY * PRODUCT.PRICE)
            INTO v_order_total
            FROM "Order" order1
                     JOIN ORDERPRODUCT ON order1.ORDER_ID = ORDERPRODUCT.ORDER_ID
                     JOIN PRODUCT ON ORDERPRODUCT.PRODUCT_ID = PRODUCT.PRODUCT_ID
            WHERE order1.ORDER_ID = i.ORDER_ID;
            UPDATE "Order"
            SET TOTAL_AMOUNT = v_order_total
            WHERE ORDER_ID = i.ORDER_ID;
        end loop;

    EXECUTE IMMEDIATE 'ALTER TABLE "Order" ADD CONSTRAINT order_paymentdetails_fk FOREIGN KEY (PAYMENT_DET_ID) REFERENCES paymentdetails (PAYMENT_DET_ID)';
    EXECUTE IMMEDIATE 'ALTER TABLE paymentdetails ADD CONSTRAINT paymentdetails_order_fk FOREIGN KEY (ORDER_ID) REFERENCES "Order" (ORDER_ID)';

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
END;

-- PAYMENTDETAILS TABLE - create payment details based on order

DECLARE
    v_status         VARCHAR2(15);
    v_payment_id     NUMBER;
    v_payment_det_id NUMBER;
BEGIN
    EXECUTE IMMEDIATE 'alter table "Order" drop constraint order_paymentdetails_fk';
    EXECUTE IMMEDIATE 'alter table PAYMENTDETAILS drop constraint paymentdetails_order_fk';

    v_payment_det_id := 1;
    FOR i IN (SELECT ROWNUM row_num, "Order".*
              FROM "Order"
              ORDER BY ORDER_ID DESC)
        LOOP
            SELECT PAYMENT_ID
            INTO v_payment_id
            FROM PAYMENT
            WHERE USER_ID = i.USER_ID
                FETCH FIRST ROW ONLY;

            CASE FLOOR(DBMS_RANDOM.VALUE(1, 4))
                WHEN 1 THEN v_status := 'PAID';
                WHEN 2 THEN v_status := 'UNPAID';
                WHEN 3 THEN v_status := 'IN_PROGRESS';
                ELSE v_status := 'BLOCKED';
                END CASE;

            INSERT INTO PAYMENTDETAILS (PAYMENT_DET_ID, STATUS, AMOUNT, CREATED_AT, MODIFIED_AT, ORDER_ID, PAYMENT_ID)
            VALUES (v_payment_det_id, v_status, i.TOTAL_AMOUNT, SYSDATE - FLOOR(DBMS_RANDOM.VALUE(1, 365)), SYSDATE,
                    i.ORDER_ID, v_payment_id);
            v_payment_det_id := v_payment_det_id + 1;

        END LOOP;

    EXECUTE IMMEDIATE 'ALTER TABLE "Order" ADD CONSTRAINT order_paymentdetails_fk FOREIGN KEY (PAYMENT_DET_ID) REFERENCES paymentdetails (PAYMENT_DET_ID)';
    EXECUTE IMMEDIATE 'ALTER TABLE PAYMENTDETAILS ADD CONSTRAINT paymentdetails_order_fk FOREIGN KEY (ORDER_ID) REFERENCES "Order" (ORDER_ID)';

    COMMIT;
EXCEPTION
    -- Roll back the transaction in case of any errors
    WHEN OTHERS THEN
        ROLLBACK;
END;

-- UPDATE ORDER TABLE - add payment details id to order rows

DECLARE
    v_payment_det_id NUMBER;
BEGIN
    FOR i IN (SELECT "Order".*
              FROM "Order")
        LOOP
            SELECT PAYMENT_DET_ID INTO v_payment_det_id FROM PAYMENTDETAILS WHERE ORDER_ID = i.ORDER_ID;
            UPDATE "Order"
            SET PAYMENT_DET_ID = v_payment_det_id
            WHERE ORDER_ID = i.ORDER_ID;
        end loop;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
END;


-- ORDERPRODUCT_DISCOUNT junction table - creating relations for many-to-many relation for orderproduct and discount

DECLARE
    v_num_of_orderproducts NUMBER;
    v_discount_id          NUMBER;
    v_num_of_discount      NUMBER;

BEGIN
    SELECT COUNT(*) INTO v_num_of_discount FROM DISCOUNT;
    SELECT FLOOR(COUNT(*) / 2) INTO v_num_of_orderproducts FROM ORDERPRODUCT;
    v_discount_id := DBMS_RANDOM.VALUE(1, v_num_of_discount);
    FOR i IN 1..v_num_of_orderproducts
        LOOP
            INSERT INTO ORDERPRODUCT_DISCOUNT (ORDERPRODUCT_ID, DISCOUNT_ID)
            VALUES (i, v_discount_id);
        end loop;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
end;


-- DROP TABLE DISCOUNT CASCADE constraints;
-- DROP TABLE "Order" CASCADE constraints;
-- DROP TABLE ORDERPRODUCT CASCADE constraints;
-- DROP TABLE ORDERPRODUCT_DISCOUNT CASCADE constraints;
-- DROP TABLE PAYMENTDETAILS CASCADE constraints;
-- DROP TABLE PAYMENT CASCADE constraints;
-- DROP TABLE "User" CASCADE constraints;
-- DROP TABLE PRODUCT CASCADE constraints;
-- DROP TABLE ORDER_LOG;