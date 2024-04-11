-- Repositorio: https://github.com/3Nacho/BasesDeDatos
-- Autores:
-- Christian Núñez Duque
-- Daniel Hermelo Puente
-- Ignacio Zaldo González

drop table clientes cascade constraints;
drop table abonos   cascade constraints;
drop table eventos  cascade constraints;
drop table reservas cascade constraints;

drop sequence seq_abonos;
drop sequence seq_eventos;
drop sequence seq_reservas;


-- Creación de tablas y secuencias

create table clientes(
  NIF varchar(9) primary key,
  nombre  varchar(20) not null,
  ape1  varchar(20) not null,
  ape2  varchar(20) not null
);


create sequence seq_abonos;

create table abonos(
  id_abono  integer primary key,
  cliente   varchar(9) references clientes,
  saldo     integer not null check (saldo>=0)
    );

create sequence seq_eventos;

create table eventos(
  id_evento integer  primary key,
  nombre_evento   varchar(20),
    fecha       date not null,
  asientos_disponibles  integer  not null
);

create sequence seq_reservas;

-- Tabla de reservas
create table reservas(
  id_reserva  integer primary key,
  cliente   varchar(9) references clientes,
    evento      integer references eventos,
  abono       integer references abonos,
  fecha date not null
);
  

CREATE OR REPLACE PROCEDURE reservar_evento(arg_NIF_cliente VARCHAR, arg_nombre_evento VARCHAR, arg_fecha DATE) IS
    evento_pasado EXCEPTION;
    PRAGMA EXCEPTION_INIT(evento_pasado, -20001);
    cliente_inexistente EXCEPTION;
    PRAGMA EXCEPTION_INIT(cliente_inexistente, -20002);
    evento_inexistente EXCEPTION;
    PRAGMA EXCEPTION_INIT(evento_inexistente, -20003);
    saldo_insuficiente EXCEPTION;
    PRAGMA EXCEPTION_INIT(saldo_insuficiente, -20004);
    asientos_insuficientes EXCEPTION;
    PRAGMA EXCEPTION_INIT(asientos_insuficientes, -20005);

    v_id_evento INTEGER;
    v_saldo INTEGER;
    v_asientos_disponibles INTEGER;
    v_cliente VARCHAR(9);
    dinero INTEGER;

BEGIN
    -- Primero, verificar si la fecha del evento es futura
    IF TRUNC(arg_fecha) < TRUNC(CURRENT_DATE) THEN
        rollback;
        RAISE_APPLICATION_ERROR(-20001, 'No se pueden reservar eventos pasados.');   
    END IF;

    -- Se cuentan las filas en las que el NIF coincide
    SELECT COUNT(*) INTO v_cliente FROM clientes WHERE NIF = arg_NIF_cliente;
    -- Si no hay coincidencias el cliente no existe
    IF v_cliente < 1 THEN
        rollback;
        RAISE_APPLICATION_ERROR(-20002, 'Cliente inexistente');
    END IF;

    -- Comprobación de si existe un evento y si hay asientos disponibles
    SELECT id_evento, asientos_disponibles INTO v_id_evento, v_asientos_disponibles
    FROM eventos
    WHERE nombre_evento = arg_nombre_evento AND fecha = arg_fecha;

    IF SQL%NOTFOUND THEN
        rollback;
        RAISE_APPLICATION_ERROR(-20003, 'El evento ' || arg_nombre_evento || ' no existe.');
    ELSIF v_asientos_disponibles < 1 THEN
        rollback;
        RAISE_APPLICATION_ERROR(-20005, 'No hay asientos disponibles para el evento.');
    END IF;

    -- Almacenar el saldo del cliente        
    SELECT saldo INTO dinero FROM abonos WHERE cliente = arg_NIF_cliente;
    -- Verificar saldo suficiente
    IF dinero < 1 THEN
        rollback;
        RAISE_APPLICATION_ERROR(-20004, 'Saldo en abono insuficiente.');
    END IF;
    
    -- Si todo es correcto, realizar la reserva
    INSERT INTO reservas (id_reserva, cliente, evento, fecha)
    VALUES (seq_reservas.NEXTVAL, arg_NIF_cliente, v_id_evento, arg_fecha);

    -- Actualizar el saldo del abono del cliente
    UPDATE abonos SET saldo = saldo - 1 WHERE cliente = arg_NIF_cliente;

    -- Disminuir los asientos disponibles del evento
    UPDATE eventos SET asientos_disponibles = asientos_disponibles - 1 WHERE id_evento = v_id_evento;
    COMMIT;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20003, 'El evento ' || arg_nombre_evento || ' no existe o el cliente no tiene abono.');

END;
/


------ Deja aquí tus respuestas a las preguntas del enunciado:
-- * P4.1 El resultado de la comprobación del paso 2 ¿sigue siendo fiable en el paso 3?:

-- Si, el resultado sigue siendo fiable en el paso 3, porque las acciones que realizamos en el paso 3 dependen
-- directamente de las condiciones que verificamos antes en el paso 2, es decir, verificamos las condiciones
-- antes de la reserva del paso 3 otra vez.



-- * P4.2 En el paso 3, la ejecución concurrente del mismo procedimiento reservar_evento con, quizás
--        otros o los mimos argumentos, ¿podría habernos añadido una reserva no recogida en esa SELECT
--        que fuese incompatible con nuestra reserva?, ¿por qué?.


-- La posible ejecución concurrente del procedimiento reservar_evento con, quizás otros o los 
-- mismos argumentos podría resultar si añadimos una reserva no recogida en ese 'SELECT', que 
-- fuese incompatible con nuestra reserva. Esto es conocido como condiciones de carrera en el 
-- acceso y modificación de los datos en un entorno de bases de datos concurrentes.



--
-- * P4.3 ¿Qué estrategia de programación has utilizado?

-- Hemos utilizado una estrategia de programación defensiva. 
-- Para ello creamos unas determinadas condiciones y a partir de ellas decidimos si hacer un commit o un rollback.



-- * P4.4 ¿Cómo puede verse este hecho en tu código?

-- Esto se puede ver a la hora de lanzar las excepciones en nuestro procedimiento donde tras hacer una consulta 
-- y obtener el resultado, evaluamos el resultado y en caso
-- de obtener algo erróneo hacemos un rollback y lanzamos la excepción correspondiente. 



--
-- * P4.5 ¿De qué otro modo crees que podrías resolver el problema propuesto? Incluye el pseudocódigo
-- 
-- Otro modo de resolver el problema sería usar una estrategia ofensiva o agresiva en vez de la defensiva que hemos usado
-- en el código que hemos realizado.

-- El pseudocódigo sería:

-- 1)  Buscar el evento y ver si la fecha del evento es más tarde de la fecha actual.
-- 2)  En caso de no encontrar el evento o que ya haya pasado, lanzariamos la una excepción.
-- 3)  Buscar al cliente y ver si tiene saldo suficiente.
-- 4)  En caso de no encontrarlo o que no tenga sufieciente saldo, lanzariamos una excepción.
-- 5)  Si es suficiente el saldo.
-- 6)  Ver si hay asientos libres.
-- 7)  Insertar la nueva reserva dentro de la tabla reservas.
-- 8)  Actualizar el saldo del cliente y reducir el número de asientos que quedarían disponibles.
-- 9)  Alguna excepción --> hacer rollback.
-- 10) Todo correcto --> confirmar con commit.



create or replace
procedure reset_seq( p_seq_name varchar )
is
    l_val number;
begin
    execute immediate
    'select ' || p_seq_name || '.nextval from dual' INTO l_val;

    execute immediate
    'alter sequence ' || p_seq_name || ' increment by -' || l_val || 
                                                          ' minvalue 0';
    execute immediate
    'select ' || p_seq_name || '.nextval from dual' INTO l_val;

    execute immediate
    'alter sequence ' || p_seq_name || ' increment by 1 minvalue 0';

end;
/


create or replace procedure inicializa_test is
begin
  reset_seq( 'seq_abonos' );
  reset_seq( 'seq_eventos' );
  reset_seq( 'seq_reservas' );
        
  
    delete from reservas;
    delete from eventos;
    delete from abonos;
    delete from clientes;
      
    insert into clientes values ('12345678A', 'Pepe', 'Perez', 'Porras');
    insert into clientes values ('11111111B', 'Beatriz', 'Barbosa', 'Bernardez');
    
    insert into abonos values (seq_abonos.nextval, '12345678A',10);
    insert into abonos values (seq_abonos.nextval, '11111111B',0);
    
    insert into eventos values ( seq_eventos.nextval, 'concierto_la_moda', date '2024-6-27', 200);
    insert into eventos values ( seq_eventos.nextval, 'teatro_impro', date '2024-7-1', 50);

    commit;
end;
/

exec inicializa_test;



-- Completa el test 
create or replace procedure test_reserva_evento is
  cont_antes_de_la_reserva INTEGER;
  cont_despues_de_la_reserva INTEGER;
begin
  -- Caso 1: Reserva correcta, se realiza
  begin
    inicializa_test;
    SELECT COUNT(*) INTO cont_antes_de_la_reserva FROM reservas;
    reservar_evento('12345678A', 'concierto_la_moda', TO_DATE('2024-06-27', 'YYYY-MM-DD'));
    SELECT COUNT(*) INTO cont_despues_de_la_reserva FROM reservas;
    IF cont_despues_de_la_reserva = cont_antes_de_la_reserva + 1 THEN
      dbms_output.put_line('T1: Prueba exitosa: La reserva se realizó correctamente.');
    ELSE
      dbms_output.put_line('T1: Prueba fallida: La cantidad de reservas no aumentó como se esperaba.');
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      dbms_output.put_line('T1: Error inesperado: ' || SQLERRM);
  end;

  -- Caso 2: Evento pasado
  begin
    inicializa_test;
    reservar_evento('12345678A', 'concierto_la_moda', TO_DATE('2023-01-01', 'YYYY-MM-DD'));
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLCODE = -20001 THEN
        dbms_output.put_line('T2: Prueba exitosa: No se pueden reservar eventos pasados.');
      ELSE
        dbms_output.put_line('T2: Error inesperado: ' || SQLERRM);
      END IF;
  end;

  -- Caso 3: Evento inexistente
  begin
    inicializa_test;
    reservar_evento('12345678A', 'evento_fantasma', TO_DATE('2024-06-28', 'YYYY-MM-DD'));
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLCODE = -20003 THEN
        dbms_output.put_line('T3: Prueba exitosa: El evento no existe.');
      ELSE
        dbms_output.put_line('T3: Error inesperado: ' || SQLERRM);
      END IF;
  end;

  -- Caso 4: Cliente inexistente
  begin
    inicializa_test;
    reservar_evento('99999999X', 'concierto_la_moda', TO_DATE('2024-06-27', 'YYYY-MM-DD'));
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLCODE = -20002 THEN
        dbms_output.put_line('T4: Prueba exitosa: Cliente inexistente.');
      ELSE
        dbms_output.put_line('T4: Error inesperado: ' || SQLERRM);
      END IF;
  end;

  -- Caso 5: El cliente no tiene saldo suficiente
  begin
    inicializa_test;
    reservar_evento('11111111B', 'concierto_la_moda', TO_DATE('2024-06-27', 'YYYY-MM-DD'));
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLCODE = -20004 THEN
        dbms_output.put_line('T5: Prueba exitosa: Saldo en abono insuficiente.');
      ELSE
        dbms_output.put_line('T5: Error inesperado: ' || SQLERRM);
      END IF;
  end;

end;
/




set serveroutput on;
exec test_reserva_evento;
