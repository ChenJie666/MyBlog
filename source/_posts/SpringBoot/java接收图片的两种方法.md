---
title: java接收图片的两种方法
categories:
- SpringBoot
---
- 从request中获取文件的输入流
- 通过MultipartFile类接收文件


```java
    @PostMapping("savePicByIo")
    public String savePicByIo(HttpServletRequest request) throws Exception{
        System.out.println("图片上传开始");
        String fileName = savePictureService.savePicByIo(request);
        return fileName;
    }

    @PostMapping("savePicByFormData")
    public String savePicByFormData(@RequestParam("file")MultipartFile file) throws IOException {
        String fileName = savePictureService.savePicByFormData(file);
        return fileName;
    }
```

```java
     public String savePicByIo(HttpServletRequest request) throws IOException {
        // 图片存储路径
        String path = "C:\image\factory";
        // 判断是否有路径
        if (!new File(path).exists()) {
            new File(path).mkdirs();
        }
        ServletInputStream inputStream = request.getInputStream();
        String fileName = UUID.randomUUID().toString().replace("-","") + ".jpg";
        File tempFile = new File(path,fileName);
        if (!tempFile.exists()) {
            OutputStream os = new FileOutputStream(tempFile);
            BufferedOutputStream bos = new BufferedOutputStream(os);
            byte[] buf = new byte[1024];
            int length;
            length = inputStream.read(buf,0,buf.length);
            while (length != -1) {
                bos.write(buf, 0 , length);
                length = inputStream.read(buf);
            }
            bos.close();
            os.close();
            inputStream.close();
        }
        return fileName;
    }


    public String savePicByFormData(MultipartFile file) throws IOException {

        // 图片存储路径
        String path = "C:\image\factory";
        // 判断是否有路径
        if (!new File(path).exists()) {
            new File(path).mkdirs();
        }
        String fileName = UUID.randomUUID().toString().replace("-","") + ".jpg";
        File tempFile = new File(path,fileName);
        if (!tempFile.exists()) {
            tempFile.createNewFile();
        }
        file.transferTo(tempFile);
        return fileName;
    }
```
