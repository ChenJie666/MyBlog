---
title: Excel文件的导入导出
categories:
- 工具类
---
###工具类
```java
public class CellTypeUtil {

    public static String cell2String(Cell cell) {
        if (Objects.isNull(cell)) {
            throw new IllegalArgumentException("cell为空");
        }
        CellType cellType = cell.getCellType();
        String cellValue = null;
        switch (cellType) {
            case STRING:
                cellValue = cell.getStringCellValue();
                break;
            case BOOLEAN:
                cellValue = String.valueOf(cell.getBooleanCellValue());
                break;
            case NUMERIC:
                double numericCellValue = cell.getNumericCellValue();
                cellValue = String.valueOf((long) numericCellValue);
                break;
            default:
                break;
//            case BLANK:
//                break;
//            case _NONE:
//                break;
//            case FORMULA:
//                break;
        }
        System.out.println("***cellValue:"+ cellValue);
        return cellValue;
    }
}
```


###代码
```java
    public void loadCodeByExcel(MultipartFile file) {
        XSSFWorkbook errWb;
        XSSFSheet errSheet;
        try {
            XSSFWorkbook wb = new XSSFWorkbook(file.getInputStream());
            Iterator<Sheet> sheetIterator = wb.sheetIterator();

            errWb = new XSSFWorkbook();
            errSheet = errWb.createSheet("errSheet");
            XSSFRow errRow0 = errSheet.createRow(0);
            errRow0.createCell(0).setCellValue("激活码");
            errRow0.createCell(1).setCellValue("导入失败原因");
            int index = 1;
            while (sheetIterator.hasNext()) {
                Sheet sheet = sheetIterator.next();
                Iterator<Row> rowIterator = sheet.rowIterator();
                while (rowIterator.hasNext()) {
                    Row row = rowIterator.next();
                    for (Cell cell : row) {
                        String cellValue = "";
                        try {
                            cellValue = CellTypeUtil.cell2String(cell);
                            Assert.isTrue(cellValue.length() == 16, "激活码不是16位");
                            int insert = baseMapper.insert(new Dragonfly().setCode(cellValue));
                            Assert.isTrue(insert != 0, "插入记录数为0");
                        } catch (Exception e) {
                            e.printStackTrace();
                            String msg = e.getMessage();
                            if (e instanceof DuplicateKeyException) {
                                msg = "已存在该激活码";
                            }
                            XSSFRow errRow = errSheet.createRow(index++);
                            errRow.createCell(0).setCellValue(cellValue);
                            errRow.createCell(1).setCellValue(msg);
                        }
                    }
                }
            }

        } catch (Exception e) {
            e.printStackTrace();
            throw new IllegalArgumentException("上传的文件解析为xml文件时出错");
        }

        if (errSheet.getPhysicalNumberOfRows() > 1) {
            BufferedOutputStream bos =null;
            try {
                String filename = "导出电台" + ".xlsx";
                response.setContentType("application/vnd.ms-excel;charset=UTF-8");
                response.setHeader("Content-Disposition", "attachment;filename=".concat(filename));

                OutputStream os = response.getOutputStream();
                bos = new BufferedOutputStream(os);
                bos.flush();
                errWb.write(bos);
            } catch (IOException e) {
                e.printStackTrace();
            }finally {
                try {
                    if(bos != null)
                        bos.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }

    }
```
