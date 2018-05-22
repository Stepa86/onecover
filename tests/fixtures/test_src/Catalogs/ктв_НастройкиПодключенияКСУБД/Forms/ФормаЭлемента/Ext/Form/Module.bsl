﻿
#Область ОбработчикиСобытийФормы

&НаСервере
Процедура ПриСозданииНаСервере(Отказ, СтандартнаяОбработка)
	
	ОбновитьСписокБазНаСервере();
	
КонецПроцедуры //ПриСозданииНаСервере()

#КонецОбласти

#Область ОбработчикиСобытийЭлементовФормы

&НаКлиенте
Процедура ПараметрыПодключенияПриИзменении(Элемент)
	
	ОбновитьСписокБазНаСервере();
	
КонецПроцедуры //ПараметрыПодключенияПриИзменении()

#КонецОбласти

#Область СлужебныеПроцедуры

// Функция - Выполняет соединение с SQL сервером используя ADODB
//
// Параметры:
//  Драйвер				 - Строка			 - Имя драйвера для соединения с внешней СУБД
//  Сервер				 - Строка			 - Имя сервера, где расположена внешняя СУБД
//  ИмяБазы				 - Строка			 - Имя базы данных во внешней СУБД
//  Пользователь		 - Строка			 - Имя пользователя для соединения с внешней СУБД
//  Пароль				 - Строка			 - Пароль пользователя для соединения с внешней СУБД
//  Соединение			 - COMОбъект		 - Соединение с внешней СУБД, полученное в результате выполнения функции
//  ТекстОшибки			 - Строка			 - Описание возникшей ошибки
// 
// Возвращаемое значение:
// 		Булево - Истина - соединение выполнено успешно, Ложь - в противном случае
//
&Насервере
Функция ПолучитьСоединениеССУБД(Драйвер, Сервер, ИмяБазы, Пользователь, Пароль, Соединение = Неопределено, ТекстОшибки = "") Экспорт
	
	Если Соединение <> Неопределено Тогда
		
		Если Соединение.State = 1 Тогда 
			Возврат Истина;
		КонецЕсли;
		
	КонецЕсли;
	
	// пытаемся соединиться с БД
	Попытка
		Соединение = Новый COMОбъект("ADODB.Connection");	
		
		СтрокаСоединения = "Driver=" + СокрЛП(Драйвер) +
						   ";server=" + СокрЛП(Сервер) +
						   ";uid=" + СокрЛП(Пользователь) +
						   ";pwd=" + СокрЛП(Пароль) +
						   ";Database=" + СокрЛП(ИмяБазы) + ";";
		
		Соединение.ConnectionTimeout = 10;
		Соединение.CommandTimeout = 0;
		Соединение.CursorLocation = 3;
		
		// Соединяемся с БД
		Соединение.Open(СтрокаСоединения); 
		
	Исключение 
		
		ТекстОшибки = ПодробноеПредставлениеОшибки(ИнформацияОбОшибке());
		Возврат Ложь;
		
	КонецПопытки;
	
	Возврат Истина;
	
КонецФункции //ПолучитьСоединениеССУБД()

// Функция - Выполняет запрос КСУБД
//
// Параметры:
//  Соединение			 - COMОбъект		 - Соединение с внешней СУБД, через которое будет выполняться запрос
//  ТекстЗапроса		 - Строка			 - Текст запроса
//  РезультатЗапроса	 - COMОбъект		 - Результат выполнения запроса
//  ТекстОшибки			 - Строка			 - Описание возникшей ошибки
// 
// Возвращаемое значение:
// 		Булево - Истина - запрос выполнен успешно, Ложь - в противном случае
//
Функция ВыполнитьЗапросКСУБД(Соединение, ТекстЗапроса, РезультатЗапроса = Неопределено, ТекстОшибки = "") Экспорт
	
	Попытка
	
		РезультатЗапроса = Соединение.Execute(ТекстЗапроса);		
	
	Исключение
		
		ТекстОшибки = ПодробноеПредставлениеОшибки(ИнформацияОбОшибке());
		Возврат Ложь;
	
	КонецПопытки; 
	
	Возврат Истина;	
	
КонецФункции //ВыполнитьЗапросКСУБД()

// Процедура - Обновляет список баз с сервера СУБД для выбора
//
&НаСервере
Процедура ОбновитьСписокБазНаСервере()
	
	Элементы.ИмяБазы.СписокВыбора.Очистить();
	
	Соединение = Неопределено;
	
	ТекстОшибки = "";
	
	Если НЕ ПолучитьСоединениеССУБД(Объект.Драйвер, Объект.Сервер, Объект.ИмяБазы, Объект.Пользователь, Объект.Пароль, Соединение, ТекстОшибки) Тогда
		Возврат;
	КонецЕсли;
	
	ТекстЗапроса = "SELECT
				   |	name
				   |
				   |FROM sys.databases
				   |
				   |WHERE name not in ('master','tempdb','model','msdb')
				   |	AND is_distributor = 0
				   |	AND isnull(source_database_id,0) = 0";
	
	РезультатЗапроса  = Неопределено;
	
	Если НЕ ВыполнитьЗапросКСУБД(Соединение, ТекстЗапроса, РезультатЗапроса, ТекстОшибки) Тогда
		Возврат;
	КонецЕсли;
	
	Пока РезультатЗапроса.EOF = 0 Цикл
			
		Для Каждого ТекКолонка Из РезультатЗапроса.Fields Цикл
			Если НЕ ВРег(ТекКолонка.Name) = ВРег("name") Тогда
				Продолжить;
			КонецЕсли;
			
			Элементы.ИмяБазы.СписокВыбора.Добавить(ТекКолонка.Value);
			
			Прервать;

		КонецЦикла;
			
		РезультатЗапроса.MoveNext();
	КонецЦикла;
	
КонецПроцедуры //ОбновитьСписокБазНаСервере()
	
#КонецОбласти
