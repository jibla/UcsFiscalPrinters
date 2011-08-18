VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "cFiscalPrinter"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
'=========================================================================
' $Header: /UcsFiscalPrinter/Src/cFiscalPrinter.cls 13    9.08.11 23:25 Wqw $
'
'   Unicontsoft Fiscal Printers Project
'   Copyright (c) 2008-2011 Unicontsoft
'
'   Uprawlenie na fiscalni ustrojstwa prez IDeviceProtocol protocoli
'
' $Log: /UcsFiscalPrinter/Src/cFiscalPrinter.cls $
' 
' 13    9.08.11 23:25 Wqw
' REF: supports zeka protocol
'
' 12    17.06.11 13:23 Wqw
' REF: enum casing
'
' 11    10.05.11 15:15 Wqw
' REF: guard GetCommandLog in err handlers
'
' 10    8.03.11 13:04 Wqw
' REF: vat group idwa numeric weche
'
' 9     23.02.11 17:10 Wqw
' REF: text const
'
' 8     22.02.11 17:38 Wqw
' REF: text consts
'
' 7     22.02.11 13:52 Wqw
' REF: EnumPorts wryshta doplnitelno speed i protocol
'
' 6     22.02.11 10:50 Wqw
' REF: GetHeaderFooter wryshta array s empty ako ne moje da dostypi FP
'
' 5     22.02.11 10:26 Wqw
' ADD: EnumPorts
'
' 4     22.02.11 10:07 Wqw
' REF: izneseni metodi w otdelen admin class
'
' 3     21.02.11 16:28 Wqw
' ADD: Property IsShared
'
' 2     21.02.11 13:46 Wqw
' REF: impl datecs fp and daisy ecr support
'
' 1     14.02.11 18:13 Wqw
' Initial implementation
'
'=========================================================================
Option Explicit
DefObj A-Z
Private Const MODULE_NAME As String = "cFiscalPrinter"

'=========================================================================
' Public enums
'=========================================================================

Public Enum UcsFiscalReportTypeEnum
    ucsFscRptDaily = 1
    ucsFscRptNumber
    ucsFscRptDate
    ucsFscRptOperator
End Enum

Public Enum UcsFiscalParamIndexesEnum
    ucsFscPixItem = 0
    ucsFscPixPrice
    ucsFscPixGroup
    ucsFscPixQuantity
    ucsFscPixDiscount
    ucsFscPixWayOfPmt = ucsFscPixPrice
    ucsFscPixAmount
    ucsFscPixInvoiceNo = 0
    ucsFscPixCgName
    ucsFscPixCgBulstat
    ucsFscPixCgVatNo
    ucsFscPixCgAddress
    ucsFscPixCgPersonReceiver
    ucsFscPixOwnPersonSeller
    ucsFscPixLnkDoc
    ucsFscPixInvoiceNoPrefix
    ucsFscPixOperatorCode = 0
    ucsFscPixOperatorName
    ucsFscPixOperatorPass
    ucsFscPixCashDeskNo
    ucsFscPixLastReceipt
    ucsFscPixFiscalPayment
End Enum

'=========================================================================
' Constants and member variables
'=========================================================================

'Private Const STR_PAYMENT               As String = "� ����|�����|� ���|������"
Private Const STR_ELTRADE_ECR_INTERNAL  As String = "�� � ������� ����������|������ ��� ��������: |������ ��� SetCommTimeouts: |������ ��� BuildCommDCB: |������ ��� SetCommState: |������ ��� WriteFile: |����� �� ������ ������ � �������� �� �������|������ ��� ReadFile: |���� ��� �������� ������|���� �������� ������|��������� �������� �� ������� �� ������������|������ ��� WaitCommEvent: |���� ��������� �������|������ ������|��������� ��������� 'Command'|����������� ������� �� ����� �� ������ �� ���� ��������|������ ��� �����|������� ������ �� ���������� ����������|���������� ��������� �� �������� ����������|������ �� ��� %1: %2"
Private Const STR_ELTRADE_ECR_TEXTS     As String = "����|�������� ����|�������� %1|��. ����|����������|����*%1|�����|������|���*%1|���� ��-��|������� #|��������:|   * * * * * * * *|���������:|����� # |���� # |%1 ��������|���:|�������:|��������|��������"
Private Const STR_DATECS_FP_INTERNAL    As String = "�� � ������� ����������|������ ��� ��������: |������ ��� SetCommTimeouts: |������ ��� BuildCommDCB: |������ ��� SetCommState: |������ ��� WriteFile: |����� �� ������ ������ � �������� �� �������|������ ��� ReadFile: |��������� ������ �� ��������� ��� ���� �� �������� (NAK)|���� ��� �������� ������|���� �������� ������|��������� ������� �� ��������|������ ������ �� ���� �� ��������|������ ������ �� ������ �� ��������|������ ��� WaitCommEvent: |���� ��������� �������| ��� ��������� ������ �� ��������|������ �� ��� %1: %2|���������� ��������� �� �������� ����������"
Private Const STR_DATECS_FP_STATUSES    As String = "����������� ������|��������� �������|������������ ���� � ���|3|������������ � ��������� �� ���������� ����������|5|6|7|����������� ����������|����������� �������|���������� �� ��������� �����|3|��������� ���������� �� ��������� �����|5|6|7|���� ������|1|2|������� �������� ���|4|������� �������� (����������) ���|6|7"
Private Const STR_DATECS_FP_ERRORS      As String = "����������� ������|��������� �������|2|3|������������ � ��������� �� ���������� ����������|5|6|7|1|����������� �������|���������� �� ��������� �����|3|��������� ���������� �� ��������� �����|5|6|7|���� ������|1|2|3|4|5|6|7"
Private Const STR_DATECS_FP_DIP_SWITCHES As String = "����������� ���������� �� header � footer|������������� header|Sw1.3|Sw1.4|�������� �� �������|��������� �������|��� ����� �� �������|7"
Private Const STR_DATECS_FP_MEMORY      As String = "������ ��� �����|1|���� ����� �������� �����|����� �������� ����� ��� ���������� �����|����� �������� �����|5|6|7|���������� ����� ��������� �� �����|����������� �������� �����|2|��������� � ��� �������� �����|�������� ������� ������|������������ ������������ ����� � ����� �� ���������� �����|6|7"
Private Const STR_DATECS_FP_TEXTS       As String = "� ����|������� �����|� ���|�������� �����|�������� %1|�������� %1|����|�������� ����|������� No %1|�������� %1|�������� ����|����������|����|������ ����� %1|��� %1=%2|���� ��������|����|%1 ��������|1 �������|�����|��������: |���������: |�������: |�����. No: |���� No: "
Private Const STR_ZEKA_FP_INTERNAL      As String = "�� � ������� ����������|������ ��� ��������: |������ ��� SetCommTimeouts: |������ ��� BuildCommDCB: |������ ��� SetCommState: |������ ��� WriteFile: |����� �� ������ ������ � �������� �� �������|������ ��� ReadFile: |��������� ������ �� ��������� ��� ���� �� �������� (NAK)|���� ��� �������� ������|���� �������� ������|��������� ������� �� ��������|������ ������ �� ������ �� ��������|������ ��� WaitCommEvent: |���� ��������� �������|������ �� ��� %1: %2|���������� ��������� �� �������� ����������"
Private Const STR_ZEKA_FP_STATUSES      As String = "���������� ������|��������� �������|����������� �������|����������� ������ ������� �����|����������� ������|���������� �� �������� ��������|����� ������ ��������|������ ���������� ����� �� �� �������|������������ ������� ����|�������� � ��������� �����"
Private Const STR_ZEKA_FP_ERRORS        As String = "���������� ������|���� ������|���������� �� �������� ��������|��������/������ ��������|������� �������� ���|������ � ������� �� �������|������� ���������� ���|������ � ���������� �������|�������� ����� ���� �� ������|������ ������ ��� ����������� �������|������� ������ �������|24 ���� ��� ������ �����|������� �������|���� �� ���������� ��� �������� ���|���������� � ������������ ��������� �����|������������ �������"
Private Const STR_ZEKA_FP_TEXTS         As String = "� ����|�����|���|��������%1|��������%1|����|�������� ����|������� No %1|�������� %1|�������� ����|����������|����*%1|������ ����� %1|���*%1=%2|���� ��������|���� ����|%1 ��������|1 ��������|�����|��������: |���������: |�������: |�����. No: |���� No: |���;���;���;�������� No|��������"
Private Const ERR_INIT_PROTOCOL         As String = "������ ��� ������������� �� �������� %1"
Private Const ERR_MISSING_ROWS          As String = "������� ������ �� �����"
Private Const STR_DUPLICATE             As String = "��������"
Private Const STR_ORIGINAL              As String = "��������"
Private Const STR_HEAD_CREDIT_NOTE2     As String = "��� �-�� "
Private Const STR_CASHIER               As String = "������"

Private Enum UcsRowTypeEnum
    ucsRwtSell = 1
    ucsRwtPayment
    ucsRwtText
End Enum

Private Type UcsRow
    Type            As UcsRowTypeEnum
    Item            As String
    Price           As String
    Discount        As String
    Group           As String
    Quantity        As String
    WayOfPayment    As String
    Amount          As String
End Type

'=========================================================================
' Error handling
'=========================================================================

'Private Sub PrintError(sFunc As String)
'    Debug.Print MODULE_NAME & "." & sFunc & ": " & Error
'    DebugLog sFunc, "Run-time error: " & Error
'End Sub

Private Sub DebugLog(sFunc As String, sText As String)
    OutputDebugLog MODULE_NAME, sFunc, sText
End Sub

'=========================================================================
' Methods
'=========================================================================

Public Function EnumPorts() As Variant
    Dim vDevices        As Variant
    Dim vRet            As Variant
    Dim lCount          As Long
    Dim vPort           As Variant
    Dim vElem           As Variant
    Dim pDevice         As IDeviceProtocol
    Dim sProtocol       As String
    Dim sModel          As String
    
    On Error Resume Next
    vDevices = Array(New cZekaProtocol, New cICLProtocol, New cEltradeProtocol)
    ReDim vRet(0 To 255) As Variant
    For Each vPort In EnumSerialPorts
        sProtocol = vbNullString
        sModel = vbNullString
        For Each vElem In vDevices
            Set pDevice = vElem
            pDevice.Init C_Str(vPort), 500, 0
            sProtocol = pDevice.GetDeviceProtocol()
            If LenB(sProtocol) <> 0 Then
                sModel = pDevice.GetDeviceModel()
                Exit For
            End If
            pDevice.Disconnect
        Next
        vRet(lCount) = Array(vPort, 9600, sProtocol, sModel)
        lCount = lCount + 1
    Next
    If lCount > 0 Then
        ReDim Preserve vRet(0 To lCount - 1) As Variant
    Else
        vRet = Split(vbNullString)
    End If
    EnumPorts = vRet
End Function

Public Function GetHeaderFooter( _
            DeviceString As String, _
            Optional OperatorData As Variant, _
            Optional RetVal As Variant, _
            Optional LastError As String, _
            Optional CommandLog As String) As Boolean
    Const FUNC_NAME     As String = "GetHeaderFooter"
    Dim oFP             As IDeviceProtocol
    Dim vInput          As Variant
    
    On Error GoTo EH
    vInput = RetVal
    ReDim RetVal(0 To 18) As Variant
    Set oFP = pvInit(DeviceString)
    If LenB(At(vInput, 0, "1")) <> 0 Then
        RetVal(0) = Trim(oFP.GetHeaderText(1))
    End If
    If LenB(At(vInput, 1, "1")) <> 0 Then
        RetVal(1) = Trim(oFP.GetHeaderText(2))
    End If
    If LenB(At(vInput, 2, "1")) <> 0 Then
        RetVal(2) = oFP.GetTaxNumber() & "," & Replace(Trim(oFP.GetTaxCaption()), ":", vbNullString)
    End If
    If LenB(At(vInput, 3, "1")) <> 0 Then
        RetVal(3) = Trim(oFP.GetHeaderText(3))
    End If
    If LenB(At(vInput, 4, "1")) <> 0 Then
        RetVal(4) = Trim(oFP.GetHeaderText(4))
    End If
    If LenB(At(vInput, 5, "1")) <> 0 Then
        RetVal(5) = Trim(oFP.GetHeaderText(5))
    End If
    If LenB(At(vInput, 6, "1")) <> 0 Then
        RetVal(6) = Trim(oFP.GetHeaderText(6))
    End If
    If LenB(At(vInput, 7, "1")) <> 0 Then
        RetVal(7) = Trim(oFP.GetFooterText(1))
    End If
    If LenB(At(vInput, 8, "1")) <> 0 Then
        RetVal(8) = Trim(oFP.GetFooterText(2))
    End If
    If LenB(At(vInput, 10, "1")) <> 0 Then
        RetVal(10) = At(OperatorData, 0)
    End If
    If LenB(At(vInput, 11, "1")) <> 0 Then
        RetVal(11) = oFP.GetClock()
    End If
    If LenB(At(vInput, 12, "1")) <> 0 Then
        RetVal(12) = oFP.GetLastReceiptNumber()
    End If
    If LenB(At(vInput, 13, "1")) <> 0 Then
        RetVal(13) = oFP.GetPaymentName(1)
    End If
    If LenB(At(vInput, 14, "1")) <> 0 Then
        RetVal(14) = oFP.GetPaymentName(2)
    End If
    If LenB(At(vInput, 15, "1")) <> 0 Then
        RetVal(15) = oFP.GetPaymentName(3)
    End If
    If LenB(At(vInput, 16, "1")) <> 0 Then
        RetVal(16) = oFP.GetPaymentName(4)
    End If
    If LenB(At(vInput, 17, "1")) <> 0 Then
        RetVal(17) = oFP.GetCharsPerLine()
    End If
    If LenB(At(vInput, 18, "1")) <> 0 Then
        RetVal(18) = oFP.GetDefaultPassword()
    End If
    '--- success
    GetHeaderFooter = True
QH:
    CommandLog = oFP.GetCommandLog()
    Exit Function
EH:
    LastError = Err.Description
    DebugLog FUNC_NAME, "LastError=" & LastError
    If Not oFP Is Nothing Then
        DebugLog FUNC_NAME, "oFP.GetLastError=" & oFP.GetLastError()
        CommandLog = oFP.GetCommandLog()
    End If
End Function

Public Function PrintReceipt( _
            DeviceString As String, _
            ByVal ReceiptType As UcsFiscalReceiptTypeEnum, _
            Rows As Variant, _
            Optional OperatorData As Variant, _
            Optional InvoiceData As Variant, _
            Optional PrintDuplicate As Boolean, _
            Optional LastError As String, _
            Optional CommandLog As String) As Boolean
    Const FUNC_NAME     As String = "PrintReceipt"
    Dim oFP             As IDeviceProtocol
    Dim vElem           As Variant
    Dim lIdx            As Long
            
    On Error GoTo EH
    Set oFP = pvInit(DeviceString)
    If IsArray(Rows) Then
        oFP.StartReceipt ReceiptType, At(OperatorData, ucsFscPixOperatorCode), _
            At(OperatorData, ucsFscPixOperatorName, STR_CASHIER), _
            At(OperatorData, ucsFscPixOperatorPass), _
            IIf(ReceiptType = ucsFscRetInvoiceNonfiscal, At(InvoiceData, ucsFscPixInvoiceNoPrefix), vbNullString) & At(InvoiceData, ucsFscPixInvoiceNo), _
            At(InvoiceData, ucsFscPixCgBulstat), _
            At(InvoiceData, ucsFscPixCgVatNo), _
            At(InvoiceData, ucsFscPixCgName), _
            vbNullString, _
            At(InvoiceData, ucsFscPixCgAddress), _
            At(InvoiceData, ucsFscPixCgPersonReceiver), _
            vbNullString
        If LenB(At(InvoiceData, ucsFscPixLnkDoc)) <> 0 Then
            oFP.AddLine STR_HEAD_CREDIT_NOTE2 & At(InvoiceData, ucsFscPixLnkDoc)
        End If
        If PrintDuplicate Then
            oFP.AddLine STR_DUPLICATE
        ElseIf ReceiptType = ucsFscRetInvoiceNonfiscal Then
            oFP.AddLine STR_ORIGINAL
        End If
        For Each vElem In Rows
            With pvGetRowData(vElem)
                Select Case .Type
                Case ucsRwtSell
                    oFP.AddPLU .Item, C_Dbl(.Price), IIf(LenB(.Quantity) <> 0, C_Dbl(.Quantity), 1), pvGetVatGroup(.Group)
                    If C_Dbl(.Discount) <> 0 Then
                        oFP.AddDiscount ucsFscDstPlu, -C_Dbl(.Discount)
                    End If
                Case ucsRwtText
                    oFP.AddLine .Item
                Case ucsRwtPayment
                    lIdx = LimitLong(C_Lng(.WayOfPayment), 1, 8)
                    oFP.AddPayment lIdx, Zn(.Item, oFP.GetPaymentName(lIdx)), C_Dbl(.Amount)
                End Select
            End With
        Next
        If Not oFP.EndReceipt() Then
            If LenB(oFP.GetLastError()) <> 0 Then
                Err.Raise vbObjectError, , oFP.GetLastError()
            End If
        End If
        oFP.OpenDrawer
        '--- success
        PrintReceipt = True
    End If
    If PrintDuplicate Then
        Select Case ReceiptType
        Case ucsFscRetNonfiscal, ucsFscRetInvoiceNonfiscal
            If IsEmpty(Rows) Then
                LastError = ERR_MISSING_ROWS
                GoTo QH
            End If
        Case Else
            If Not oFP.CopyLastReceipt() Then
                LastError = oFP.GetLastError()
                GoTo QH
            End If
            '--- success
            PrintReceipt = True
        End Select
    End If
    If LenB(At(OperatorData, ucsFscPixLastReceipt, vbNullString)) <> 0 Then
        OperatorData(ucsFscPixLastReceipt) = oFP.GetLastReceiptNumber()
    End If
    If LenB(At(OperatorData, ucsFscPixFiscalPayment, vbNullString)) <> 0 Then
        OperatorData(ucsFscPixFiscalPayment) = oFP.GetPaymentExecuted()
    End If
QH:
    CommandLog = oFP.GetCommandLog()
    Exit Function
EH:
    LastError = Err.Description
    DebugLog FUNC_NAME, "LastError=" & LastError
    If Not oFP Is Nothing Then
        DebugLog FUNC_NAME, "oFP.GetLastError=" & oFP.GetLastError()
        CommandLog = oFP.GetCommandLog()
    End If
End Function

Public Function PrintReport( _
            DeviceString As String, _
            ByVal ReportType As UcsFiscalReportTypeEnum, _
            Optional ReportData As Variant, _
            Optional LastError As String, _
            Optional CommandLog As String) As Boolean
    Const FUNC_NAME     As String = "PrintReport"
    Dim oFP             As IDeviceProtocol
    
    On Error GoTo EH
    Set oFP = pvInit(DeviceString)
    Select Case ReportType
    Case ucsFscRptDaily
        '-- ReportData = { IsClear, IsItems, IsDepartments }
        If C_Bool(At(ReportData, 1)) And C_Bool(At(ReportData, 2)) Then
            If C_Bool(At(ReportData, 0)) Then
                oFP.RunZReport ucsFscRstDailyByItemsAndDepartment
            Else
                oFP.RunXReport ucsFscRstDailyByItemsAndDepartment
            End If
        ElseIf C_Bool(At(ReportData, 1)) Then
            If C_Bool(At(ReportData, 0)) Then
                oFP.RunZReport ucsFscRstDailyByItems
            Else
                oFP.RunXReport ucsFscRstDailyByItems
            End If
        ElseIf C_Bool(At(ReportData, 2)) Then
            If C_Bool(At(ReportData, 0)) Then
                oFP.RunZReport ucsFscRstDailyByDepartment
            Else
                oFP.RunXReport ucsFscRstDailyByDepartment
            End If
        Else
            If C_Bool(At(ReportData, 0)) Then
                oFP.RunZReport ucsFscRstDaily
            Else
                oFP.RunXReport ucsFscRstDaily
            End If
        End If
    Case ucsFscRptNumber
        '-- ReportData = { FromNum, ToNum, IsDetailed }
    Case ucsFscRptDate
        '-- ReportData = { FromDate, ToDate, IsDetailed }
        If C_Date(At(ReportData, 0)) <> 0 And C_Date(At(ReportData, 1)) <> 0 Then
            oFP.RunPeriodReport IIf(C_Bool(At(ReportData, 2)), ucsFscRstPeriodDetailed, ucsFscRstPeriodShort), C_Date(At(ReportData, 0)), C_Date(At(ReportData, 1))
        End If
    Case ucsFscRptOperator
        '-- ReportData = Empty
        
    End Select
    '--- success
    PrintReport = True
QH:
    CommandLog = oFP.GetCommandLog()
    Exit Function
EH:
    LastError = Err.Description
    DebugLog FUNC_NAME, "LastError=" & LastError
    If Not oFP Is Nothing Then
        DebugLog FUNC_NAME, "oFP.GetLastError=" & oFP.GetLastError()
        CommandLog = oFP.GetCommandLog()
    End If
End Function

Public Function OpenDrawer( _
            DeviceString As String, _
            Optional LastError As String, _
            Optional CommandLog As String) As Boolean
    Const FUNC_NAME     As String = "OpenDrawer"
    Dim oFP             As IDeviceProtocol
    
    On Error GoTo EH
    Set oFP = pvInit(DeviceString)
    '--- success (or failure)
    OpenDrawer = oFP.OpenDrawer()
QH:
    CommandLog = oFP.GetCommandLog()
    Exit Function
EH:
    LastError = Err.Description
    DebugLog FUNC_NAME, "LastError=" & LastError
    If Not oFP Is Nothing Then
        DebugLog FUNC_NAME, "oFP.GetLastError=" & oFP.GetLastError()
        CommandLog = oFP.GetCommandLog()
    End If
End Function

Public Function InitDateTime( _
            DeviceString As String, _
            sDateTime As String, _
            Optional LastError As String, _
            Optional CommandLog As String) As Boolean
    Const FUNC_NAME     As String = "InitDateTime"
    Dim oFP             As IDeviceProtocol
    
    On Error GoTo EH
    Set oFP = pvInit(DeviceString)
    If C_Date(sDateTime) = 0 Then
        oFP.SetClock Now
    Else
        oFP.SetClock C_Date(sDateTime)
    End If
    sDateTime = oFP.GetClock()
    '--- success
    InitDateTime = True
QH:
    CommandLog = oFP.GetCommandLog()
    Exit Function
EH:
    LastError = Err.Description
    DebugLog FUNC_NAME, "LastError=" & LastError
    If Not oFP Is Nothing Then
        DebugLog FUNC_NAME, "oFP.GetLastError=" & oFP.GetLastError()
        CommandLog = oFP.GetCommandLog()
    End If
End Function

'= private ===============================================================

Private Function pvInit(DeviceString As String) As IDeviceProtocol
    Dim vSplit          As Variant
    
    vSplit = Split(DeviceString, ";")
    '--- figure out model
    Select Case UCase$(At(vSplit, 0))
    Case STR_PROTOCOL_ELTRADE_ECR
        Set pvInit = New cEltradeProtocol
        pvInit.SetLocalizedText ucsFscLciInternalErrors, STR_ELTRADE_ECR_INTERNAL
        pvInit.SetLocalizedText ucsFscLciReceiptTexts, STR_ELTRADE_ECR_TEXTS
    Case STR_PROTOCOL_DATECS_FP, STR_PROTOCOL_DAISY_ECR
        Set pvInit = New cICLProtocol
        pvInit.SetLocalizedText ucsFscLciInternalErrors, STR_DATECS_FP_INTERNAL
        pvInit.SetLocalizedText ucsFscLciPrinterStatuses, STR_DATECS_FP_STATUSES
        pvInit.SetLocalizedText ucsFscLciPrinterErrors, STR_DATECS_FP_ERRORS
        pvInit.SetLocalizedText ucsFscLciDipSwitchesTexts, STR_DATECS_FP_DIP_SWITCHES
        pvInit.SetLocalizedText ucsFscLciMemoryTexts, STR_DATECS_FP_MEMORY
        pvInit.SetLocalizedText ucsFscLciReceiptTexts, STR_DATECS_FP_TEXTS
    Case STR_PROTOCOL_ZEKA_FP
        Set pvInit = New cZekaProtocol
        pvInit.SetLocalizedText ucsFscLciInternalErrors, STR_ZEKA_FP_INTERNAL
        pvInit.SetLocalizedText ucsFscLciPrinterStatuses, STR_ZEKA_FP_STATUSES
        pvInit.SetLocalizedText ucsFscLciPrinterErrors, STR_ZEKA_FP_ERRORS
        pvInit.SetLocalizedText ucsFscLciReceiptTexts, STR_ZEKA_FP_TEXTS
    Case Else
        Set pvInit = New cEltradeProtocol
        pvInit.SetLocalizedText ucsFscLciInternalErrors, STR_ELTRADE_ECR_INTERNAL
        pvInit.SetLocalizedText ucsFscLciPrinterErrors, STR_DATECS_FP_ERRORS
    End Select
    If Not pvInit.Init(At(vSplit, 1, "COM1"), C_Lng(At(vSplit, 2)), C_Lng(At(vSplit, 3))) Then
        Err.Raise vbObjectError, , Printf(ERR_INIT_PROTOCOL, At(vSplit, 0, STR_NONE))
    End If
End Function

Private Function pvGetRowData(vRow As Variant) As UcsRow
    On Error Resume Next
    If UBound(vRow) = ucsFscPixItem Then
        pvGetRowData.Type = ucsRwtText
        pvGetRowData.Item = C_Str(vRow(ucsFscPixItem))
    ElseIf UBound(vRow) = ucsFscPixAmount Then
        pvGetRowData.Type = ucsRwtPayment
        pvGetRowData.Item = C_Str(vRow(ucsFscPixItem))
        pvGetRowData.WayOfPayment = C_Str(vRow(ucsFscPixWayOfPmt))
        pvGetRowData.Amount = C_Str(vRow(ucsFscPixAmount))
    Else
        pvGetRowData.Type = ucsRwtSell
        pvGetRowData.Item = C_Str(vRow(ucsFscPixItem))
        pvGetRowData.Price = C_Str(vRow(ucsFscPixPrice))
        pvGetRowData.Group = C_Str(vRow(ucsFscPixGroup))
        pvGetRowData.Quantity = C_Str(vRow(ucsFscPixQuantity))
        pvGetRowData.Discount = At(vRow, ucsFscPixDiscount)
    End If
    On Error GoTo 0
End Function

Private Function pvGetVatGroup(sVatGroup As String) As Long
    pvGetVatGroup = C_Lng(sVatGroup)
    If pvGetVatGroup < 1 Or pvGetVatGroup > 8 Then
        pvGetVatGroup = 2
    End If
End Function