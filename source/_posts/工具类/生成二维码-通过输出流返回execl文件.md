---
title: 生成二维码-通过输出流返回execl文件
categories:
- 工具类
---
###生成二维码的工具类
***依赖***
```
        <dependency>
            <groupId>com.google.zxing</groupId>
            <artifactId>core</artifactId>
            <version>3.3.0</version>
        </dependency>
        <dependency>
            <groupId>com.google.zxing</groupId>
            <artifactId>javase</artifactId>
            <version>3.3.0</version>
        </dependency>
```
```java
public class QRcodeUtil {

    public static byte[] getQRcode(String text) throws WriterException, IOException {

        // 定义参数
        int width = 300;
        int height = 300;

        // 定义二维码的参数  hints调用put函数设置字符集,间距以及纠错度为M
        Map<EncodeHintType, Object> hints = new HashMap<EncodeHintType, Object>(16);
        hints.put(EncodeHintType.CHARACTER_SET, "utf-8");
        hints.put(EncodeHintType.ERROR_CORRECTION, ErrorCorrectionLevel.M);
        hints.put(EncodeHintType.MARGIN, 2);

        // 创建zxing架包支持的对象
        QRCodeWriter qrCodeWriter = new QRCodeWriter();
        // 调用该对象中包含的方法,使用QR_CODE格式进行编码
        BitMatrix bitMatrix = qrCodeWriter.encode(text, BarcodeFormat.QR_CODE, width, height, hints);
        // 创建字节数组输出流对象
        ByteArrayOutputStream pngOutputStream = new ByteArrayOutputStream();
        // 二维码的生成需要借助MatrixToImageWriter类，该类是由Google提供的生产条形码的基类
        MatrixToImageWriter.writeToStream(bitMatrix, "PNG", pngOutputStream);
        // 转换成为字节数组
        return pngOutputStream.toByteArray();
    }

}
```

***返回图片格式的二维码***
```java
    public ResponseEntity<Object> insert(Wine wine) throws WriterException, IOException {

        byte[] qRcode;
        HttpHeaders headers = new HttpHeaders();
        if (insert == 0) {
            CommonResult<Wine> result = new CommonResult<>(500, "添加失败");
            headers.setContentType(MediaType.APPLICATION_JSON);
            return new ResponseEntity<>(result, headers, HttpStatus.INTERNAL_SERVER_ERROR);
        }

        qRcode = QRcodeUtil.getQRcode(url + "?id=" + wine.getId());

        //返回生成的字节数组，在请求头中设置为图片格式；
        headers.setContentType(MediaType.IMAGE_PNG);
        return new ResponseEntity<>(qRcode, headers, HttpStatus.CREATED);
    }
```


###导出为excel文件（通过POI工具写出）
***依赖***
```java
        <!-- xls(03) -->
        <dependency>
            <groupId>org.apache.poi</groupId>
            <artifactId>poi</artifactId>
            <version>3.9</version>
        </dependency>
        <!-- xlsx(07) -->
        <dependency>
            <groupId>org.apache.poi</groupId>
            <artifactId>poi-ooxml</artifactId>
            <version>3.9</version>
        </dependency>
```
区别：03版最多只能写65536行数据，而07版能写任意行的数据。HSSFWorkbook是03版的对象，XSSFWorkbook和SXSSFWorkbook都是07版的对象，SXSSFWorkbook速度快内存占用小（注意需要清除临时文件workbook.dispose()）。
***生成excel的工具类***
```java
public class ExeclExportUtil implements Serializable {

    public static HSSFWorkbook execlExport(Map<String, List<UserHour>> map, String startDate, String endDate) {
        HSSFWorkbook wb = null;
        try {
            //创建HSSFWorkbook对象(excel的文档对象)
            wb = new HSSFWorkbook();
            // 建立新的sheet对象（excel的表单）
            HSSFSheet sheet = wb.createSheet("UserHour");
            // 在sheet里创建第一行，参数为行索引(excel的行)，可以是0～65535之间的任何一个
            HSSFRow row0 = sheet.createRow(0);
            // 添加表头
            row0.createCell(0).setCellValue("姓名");
            row0.createCell(1).setCellValue("ID");
            sheet.setColumnWidth(1,4000);

            // 得到所有日期并插入表头
            List<String> datelist = new ArrayList<>();
            String sDate = startDate.substring(0, 10);
            String eDate = endDate.substring(0, 10);
            for (int i = 2; sDate.compareTo(eDate) <= 0; i++, sDate = oneDayPlus(sDate)) {
                int re = sDate.compareTo(eDate);
                datelist.add(sDate);
                row0.createCell(i).setCellValue(sDate);
                sheet.setColumnWidth(i,4000);
            }

            // 添加表中内容
            Set<String> ids = map.keySet();
            int row = -1;
            for (String id : ids) {
                HSSFRow newrow = sheet.createRow(++row + 1);//数据从第二行开始
                List<UserHour> whlist = map.get(id);
                newrow.createCell(0).setCellValue(whlist.get(0).getDisplayName());
                newrow.createCell(1).setCellValue(id);
                for (int i = 0; i < datelist.size(); i++) {
                    for (UserHour UserHour : whlist) {
                        String date = datelist.get(i);
                        String whdate = UserHour.getWorkDay().substring(0, 10);
                        if (whdate.equals(date)) {
                            newrow.createCell(i + 2).setCellValue(UserHour.getWorkHour());
                        }
                    }
                }
            }

        } catch (
                Exception e)

        {
            e.printStackTrace();
        }

//        StreamUtil.outputStream(wb,filepath,startDate,endDate);
        return wb;
    }
}
```

***返回excel文件***
```java
@GetMapping(value = "getWorkHourListOrderByName")
public Result getWorkHourListOrderByName(@RequestParam("startDate") String startDate, @RequestParam("endDate") String endDate, @RequestParam(name = "doExport", defaultValue = "0") String doPrint, HttpServletResponse response) {
        SimpleDateFormat format = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
        Query query = new Query();
        Criteria criteria = new Criteria();
        try {
            criteria.andOperator(Criteria.where("workDay").lte(format.parse(endDate)),
                    Criteria.where("workDay").gte(format.parse(startDate)));
        } catch (ParseException e) {
            e.printStackTrace();
        }
        query.addCriteria(criteria);
        List<WorkHour> nbList = mongoTemplate.find(query, WorkHour.class);
        Map<String, List<UserHour>> map = new HashMap<>();
        for (WorkHour wh : nbList) {
            String userCode = wh.getUserCode();
            Date wd = wh.getWorkDay();
            String workDay = format.format(wd);
            String totalHour = wh.getTotalWorkHour();
            Query query1 = Query.query(Criteria.where("username").is(userCode));
            UserInfo user = mongoTemplate.findOne(query1, UserInfo.class);
            UserHour userHour = null;
            try {
                String name = user.getDisplayName();
                userHour = new UserHour();
                userHour.setUserCode(userCode);
                userHour.setDisplayName(name);
                userHour.setWorkDay(workDay);
                userHour.setWorkHour(totalHour);
            } catch (Exception e) {
                e.printStackTrace();
            }

            boolean key = map.containsKey(userCode);
            if (key) {
                List<UserHour> list = map.get(userCode);
                list.add(userHour);
                map.put(userCode, list);
            } else {
                List<UserHour> hourList = new ArrayList<>();
                hourList.add(userHour);
                map.put(userCode, hourList);
            }


        }

        if (!"0".equals(doPrint)) {
            String sDate = startDate.substring(0, 10);
            String eDate = endDate.substring(0, 10);
            HSSFWorkbook wb = ExeclExportUtil.execlExport(map, sDate, eDate);
//            StreamUtil.outputStream(wb,"D:\workhour\",sDate,eDate);
            String filename = sDate + "~" + eDate + ".xls";
            BufferedOutputStream bos = null;
            try {
                response.setContentType("application/ms-excel;charset=UTF-8");
                response.setHeader("Content-Disposition", "attachment;filename=".concat(filename));

                OutputStream os = response.getOutputStream();
                bos = new BufferedOutputStream(os);
                bos.flush();
                wb.write(bos);
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
            return null;
        }else {
            Result result = new Result();
            result.setCode("200");
            result.setData(map);

            result.setMsg("success");
            return result;
        }
    }
```
