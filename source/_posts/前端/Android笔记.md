---
title: Android笔记
categories:
- 前端
---
1.目录作用：

drawable：放图片和xml文件夹

layout：放布局xml文件

mipmap：存放应用图标

values：放置字符串

build.gradle：编译工具的版本控制和依赖库

AndroidManifest.xml：整个项目的配置文件，程序中的四大组件都在这里注册，给应用程序添加权限声明。



2.@string/tv_test  可以从values文件夹下的string文件中读取定义的字符串



3.android:text="胡涛爱学习"

android:textSize="60sp"

android:textColor="#909900"

android:maxLines="1"

android:ellipsize="end"

文字相关的有五个标签。注意，需要把上面文字相关的单位改为sp，其他单位是dp。



android:drawableLeft="@drawable/row"

android:drawablePadding="30dp"

图片相关两个标签

textStyle＝“bold” 字体加粗



4.mTv_4 = (TextView)findViewById(R.id.tv_4);//获取该对象赋值给变量

mTv_4.getPaint().setFlags(Paint.STRIKE_THRU_TEXT_FLAG);//将该文本视图中加横线

mTv_4.getPaint().setAntiAlias(true);//去除锯齿



5.mBtnTextView = (Button) findViewById(R.id.btn_textview);//将View类型强转为其子类Button类

mBtnTextView.setOnClickListener(new View.OnClickListener() {

    @Override

    public void onClick(View v) {

        //跳转到TextView演示界面

        Intent intent = new Intent(MainActivity.this,TextViewActivity.class);

        startActivity(intent);

    }

});



页面跳转



6.mtv_5 = (TextView)findViewById(R.id.tv_5);

mtv_5.getPaint().setFlags(Paint.UNDERLINE_TEXT_FLAG);//文本加下划线



7.mtv_6 = (TextView) findViewById(R.id.tv_6);

mtv_6.setText(Html.fromHtml("<u><span style=\"color:#F00\">胡涛在学习</span></u>"));

mtv_6.setTextSize(TypedValue.COMPLEX_UNIT_DIP,30);

//可以在java代码中调用html类来输出html格式的text文字



8.android:text=""

android:drawableRight="@drawable/row"

android:drawablePadding="20sp"

//接上面代码，文字大小只能在java代码中设置。该表格还是正常，箭头也是正常的。



9.android:singleLine="true"

android:ellipsize="marquee"

android:marqueeRepeatLimit="marquee_forever"

android:focusable="true"

android:focusableInTouchMode="true"

//跑马灯效果，需要...省略才能跑起来



10.android:id

android:layout_width

android:layout_height

android:background="#100000"

android:padding

android:layout_margin

android:gravity center 在布局中的位置

android:layout_weight

android:layout_above="@+id/view_1"



android:maxLines="1" //控制行数

android:visibility="invisible" //visible可见、invisible不可见、gone不可见且不留位置



LinearLayout  线性布局标签

android:orientation  horizontal、vertical





RelativeLayout 相对布局标签

android:layout_alignParentEnd="true"

android:layout_alignParentBottom="true"//与父控件的边缘对齐



android:layout_toLeftOf="@+id/view_1"

android:layout_toRightOf="@id/view_11"//与其他view的相对位置

layout_above和layout_below是属于RelativeLayout标签的



11.button圆角

在drawable文件夹下创建一个drawable  .xml文件，文件中的shape标签中加上android:shape="rectangle"，

<solid

    android:color="#FF9900"/>

<corners

    android:radius="20dp"/>

在background中调用该xml文件。





button描边

将solid标签换成

<stroke

    android:width="2dp"

    android:color="#000FFF"/>



button按压效果

用selector标签

<item android:state_pressed="true">

    <shape>

        <solid

            android:width="2dp"

            android:color="#FF9900"/>

        <corners android:radius="10dp"/>

    </shape>

</item>

<item android:state_pressed="false">

    <shape>

        <stroke

            android:width="3dp"

            android:color="#FF0000"/>

        <corners android:radius="20dp"/>

    </shape>

</item>

用item包装点击和非点击的样式



12.添加点击弹框

方式一：

btn_4.setOnClickListener(new View.OnClickListener() {

    @Override

    public void onClick(View v) {

        Toast.makeText(TextButton.this,"我被点击了",Toast.LENGTH_SHORT).show();

    }

});

方式二：

在xml文件中添加 android:onClick="showToast"

public void showToast(View view){

    Toast.makeText(this,"wait for response",Toast.LENGTH_SHORT).show();

}

点击事件TextView类也可以实现，方式二可以自己命名。



13.EditText：用于输入和监听输入的事件，制作登录界面

EditText标签中可以用text指定输入的文字的大小和颜色；用hint来做提示文字；android:inputType="number"指定输入类型；android:inputType="textPassword"指定输入隐藏；通过drawable在输入框找那个插入图片；

可以实时监控text的输入：

editText.addTextChangedListener(new TextWatcher() {

    @Override

    public void beforeTextChanged(CharSequence s, int start, int count, int after) {



    }



    @Override

    public void onTextChanged(CharSequence s, int start, int before, int count) {



    }



    @Override

    public void afterTextChanged(Editable s) {



    }

});

onTextChang方法每改变一个字符就调用一次。通过Log.d("输出:",s.toString)打印到控制台

字母设置为小写：android:textAllCaps="false"



14.多个按键事件可以将共同的提取出来：

private void setListeners(){

    OnClick onClick = new OnClick();

    mBtnTextView.setOnClickListener(onClick);

    mBtnButton.setOnClickListener(onClick);

    mBtnEditText.setOnClickListener(onClick);

    mBtnRadioButton.setOnClickListener(onClick);

}



private class OnClick implements View.OnClickListener{



    Intent intent;



    @Override

    public void onClick(View v) {

        switch (v.getId()) {

            case R.id.btn_textview:

                Intent intent = new Intent(MainActivity.this, TextViewActivity.class);

                startActivity(intent);

                break;

            case R.id.btn_text:

                intent = new Intent(MainActivity.this, TextButton.class);

                startActivity(intent);

                break;

            case R.id.edittext:

                intent = new Intent(MainActivity.this, EditTextActivity.class);

                startActivity(intent);

                break;

            case R.id.btn_radio:



15.通过RadioButton标签可以制作选择器圆点。用RadioGroup可以对许多RadioButton进行单选。

android:checked="true"  默认选中该RadioButton

android:button="@null"  去掉前面的小圆点；

drawable中需要设置state_checked="true"来表示是否选中。



16.复选框CheckBox：

标签为CheckBox

通过如下xml文件来设置选中和未选中时的图标

<item android:state_checked="false" android:drawable="@drawable/cryface"/>

<item android:state_checked="true" android:drawable="@drawable/smileface"/>

通过button标签来引用，通过paddingleft标签来隔开图标和文字



打印和获取CheckBox的信息：

mCb5.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {

    @Override

    public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {

        Toast.makeText(CheckBoxActivity.this, isChecked ? "已选中" : "已取消", Toast.LENGTH_SHORT).show();

    }

});



17.图片展示标签ImageView：

android:src="@drawable/row" 设置图片

android:scaleType="centerCrop" fitXY铺满，fitCenter宽高比不变完全显示，centerCrop宽高比不变覆盖控件



在src中可以设置本地图片，也可以在java代码中设置网络图片：

使用第三方库Glide拉取网络图片，在build.gradle引入glide包，需要在AndroidManifest中设置允许联网<uses-permission android:name="android.permission.INTERNET"/>

在Activity中设置加载网络图片

mIv2 = (ImageView) findViewById(R.id.iv_2);

Glide.with(this).load("图片地址").into(mIv2);



18.网状视图GridView

需要定义两个类和两个layout布局：GridViewActivity类绑定activity_gridview.xml布局，并通过mGv.setAdapter(new GridViewAdapter(GridViewActivity.this));来定义网状视图中每个格子的布局。在GridViewActivity类中，

public class GridViewAdapter extends BaseAdapter {

    private Context mContext;  //TODO 上下文

    private LayoutInflater mLayoutInflater; //TODO 布局填充器

    public GridViewAdapter(Context context){    //TODO 有参构造器，传入上下文

        this.mContext = context;

        mLayoutInflater = LayoutInflater.from(context); //TODO 获取布局填充器

    }

    @Override

    public int getCount() {

        return 100;  //TODO 网状视图数量

    }

    @Override

    public Object getItem(int position) {

        return null;

    }

    @Override

    public long getItemId(int position) {

        return 0;

    }

    static class ViewHolder{    //TODO 网状视图的格子，包括图片和文字

        public ImageView imageView1;

        public ImageView imageView2;

        public TextView textView;

    }

    private int tag = 0;

    @Override

    public View getView(int position, View convertView, ViewGroup parent) { //TODO 若view布局不同，加载view和值；若view布局相同，则只加载值

        ViewHolder viewHolder = null;  //TODO 网状视图的格子

        if(convertView==null){

            convertView = mLayoutInflater.inflate(R.layout.layout_gridview,null);  //TODO 通过布局填充器载入需要加载的布局资源和将当前载入的视图绑定到层级结构中的根视图中(为null表示不绑定)

            viewHolder = new ViewHolder();  //TODO 创建格子

            viewHolder.imageView1 = (ImageView)convertView.findViewById(R.id.iv_grid1);  //TODO 获取id对应的布局ImageView

            viewHolder.imageView2 = (ImageView)convertView.findViewById(R.id.iv_grid2);  //TODO 获取id对应的布局ImageView

            viewHolder.textView = (TextView)convertView.findViewById(R.id.tv_title);    //TODO 获取id对应的布局TextView

            convertView.setTag(viewHolder); //TODO 将索引给View对象，后面进行赋值

        }else{

            viewHolder = (ViewHolder)convertView.getTag();  //TODO 取出ViewHolder对象用于赋值

        }

        //TODO 给TextView对象和ImageView对象赋值

        viewHolder.textView.setText("花");

        Glide.with(mContext).load("http://xxx").into(viewHolder.imageView1);

Glide.with(mContext).load("http://xxx").into(viewHolder.imageView2);

        return convertView; //TODO 返回视图View

    }

}



屏幕上显示的网状图都是新建的converView，当向下滑动出现新的网格时，会对之前创建的converView进行复用，因为大多数情况下item的View是相同的。



定义一个网状视图的布局：

<GridView

    android:id="@+id/gv_1"

    android:layout_width="match_parent"

    android:layout_height="wrap_content"

    android:numColumns="2"

    android:horizontalSpacing="50dp"

    android:verticalSpacing="20dp"/>

定义网状视图格子的布局：

可以插入ImageView、TextView等



19.滚动视图

垂直滚动：ScrollView

水平滚动：HorizontalScrollView

每个标签中只能有一个元素



20.RecyclerView中

设置layout，<androidx.recyclerview.widget.RecyclerView/>是RecyclerView的空间。通过Activity关联该layout，

mRvMain = (RecyclerView) findViewById(R.id.rv_main);

mRvMain.setLayoutManager(new LinearLayoutManager(LinearRecyclerViewActivity.this));

mRvMain.setAdapter(new LinearAdapter(LinearRecyclerViewActivity.this）;通过创建Adapter类来处理RecyclerView中的item。



21.public class LinearAdapter extends RecyclerView.Adapter<LinearAdapter.LinearViewHolder> {

    private Context mContext;  //TODO Activity类的对象（上下文）

    private List<String> list;  //TODO 存放格子中的内容

    private OnItemClickListener mlistener;

    public LinearAdapter(Context context,List<String> list,OnItemClickListener listener){

        this.mContext = context;

        this.list = list;

        this.mlistener = listener;

    }

    @NonNull

    @Override

    public LinearViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {

        return new LinearViewHolder(LayoutInflater.from(mContext).inflate(R.layout.layout_linear_item,parent,false),list);  //TODO ViewHolder是格子的模版；inflate方法将layout转换为View对象

    }

    @Override

    public void onBindViewHolder(@NonNull LinearViewHolder holder, final int position) {

        holder.textView.setText(list.get(position));      //TODO 此处可以对layout中的内容进行修改

        holder.itemView.setOnClickListener(new View.OnClickListener() {

            @Override

            public void onClick(View v) {

//                Toast.makeText(mContext, "position:" + position, Toast.LENGTH_SHORT).show();    //设置点击事件

                mlistener.onClick(position);

            }

        });

        holder.itemView.setOnLongClickListener(new View.OnLongClickListener() {

            @Override

            public boolean onLongClick(View v) {

                mlistener.onLongClick(position);

                return true;

            }

        });

    }

    @Override

    public int getItemCount() {    //列表长度

        return list.size();

    }

    class LinearViewHolder extends RecyclerView.ViewHolder{

        private TextView textView;  //将layout转换为view后，通过view对layout中的元素进行操作

        public LinearViewHolder(@NonNull View itemView,List list) {  //构造方法,传入视图转化过来的view对象，和存储了内容的list对象

            super(itemView);

            textView = itemView.findViewById(R.id.rv_tv_1);

        }

    }

    public interface OnItemClickListener{

        void onClick(int pos);

void onLongClick(int pos);

  }

}



22.可以在values中设置dimens.xml文件来定义下划线

<?xml version="1.0" encoding="UTF-8" ?>

<resources>

    <dimen name="dividerHeight">3dp</dimen>

</resources>

通过mRvMain.addItemDecoration(new MyDecoration());  //onDraw方法(视图绘制前生效),onDrawOver(视图绘制后生效),getItemOffsets(在item周边绘制) 来为item绘制（划线颜色和background颜色一致）。

//TODO 为每个格子下面添加线

class MyDecoration extends RecyclerView.ItemDecoration{

    @Override

    public void getItemOffsets(@NonNull Rect outRect, @NonNull View view, @NonNull RecyclerView parent, @NonNull RecyclerView.State state) {

        super.getItemOffsets(outRect, view, parent, state);

        outRect.set(0,0,0,getResources().getDimensionPixelOffset(R.dimen.dividerHeight));

    }

}



23.在Activity类中设置点击事件，可以通过回调函数实现。



24.设置横向滑动的RecyclerView

LinearLayoutManager layoutManager =  new LinearLayoutManager(LinearRecyclerViewActivity.this);

layoutManager.setOrientation(LinearLayoutManager.HORIZONTAL);

mRvMainHo.setLayoutManager(layoutManager);



25.网格布局

GridLayoutManager gridLayoutManager = new GridLayoutManager(LinearRecyclerViewActivity.this, 3);

mRvMainGrid.setLayoutManager(gridLayoutManager);



26.瀑布流布局

mRv.setLayoutManager(new StaggeredGridLayoutManager(2,StaggeredGridLayoutManager.HORIZONTAL));



轮子：addHeadView、addFootView、下拉刷新、上拉加载



27.如果一个adapter（即一个RecyclerView）中需要引入两类item，需要定义两个holder类（即两个item），在getItemViewType方法中添加返回值，通过viewType判断要放哪个holder



28.WebView

通过在main下创建assets文件夹，可以访问其中的.html页面

mWv.loadUrl("file:///android_asset/text.html");



29.加载网络上的网页

mWv.getSettings().setJavaScriptEnabled(true);//如果有js，需要设置js可用

mWv.loadUrl("https://m.baidu.com");



30.新建类继承WebVeiwClient，改写方法：

class MyWebViewClient extends WebViewClient{

    @Override

    public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest request) {

        view.loadUrl(request.getUrl().toString());  //TODO 在该WebView中加载请求而不跳转到浏览器

        return true;

    }

    @Override

    public void onPageStarted(WebView view, String url, Bitmap favicon) {

        super.onPageStarted(view, url, favicon);

        Toast.makeText(WebViewActivity.this,"onPageStart...",Toast.LENGTH_SHORT).show();

    }

    @Override

    public void onPageFinished(WebView view, String url) {

        super.onPageFinished(view, url);

        Toast.makeText(WebViewActivity.this,"onPageFinished...",Toast.LENGTH_SHORT).show();

    }

}

对元素进行设置：

mWv.setWebViewClient(new MyWebViewClient());    //TODO 设置WebView的客户端属性



后退键不会回退到Activity处：

@Override

public boolean onKeyDown(int keyCode, KeyEvent event) {

    if (keyCode == KeyEvent.KEYCODE_BACK && mWv.canGoBack()) {  //TODO 是会退操作且可以回退

        mWv.goBack();

        return true;    //TODO 返回true结束

    }

    return super.onKeyDown(keyCode, event); //TODO 退到Activity

}



31.另一种WebView客户端

class MyWebChromeClient extends WebChromeClient {

    @Override

    public void onProgressChanged(WebView view, int newProgress) {

        super.onProgressChanged(view, newProgress); //加载进度

    }

    @Override

    public void onReceivedTitle(WebView view, String title) {

        super.onReceivedTitle(view, title);

        setTitle(title);    //TODO 设置html的title属性

    }

}

mWv.setWebChromeClient(new MyWebChromeClient());//TODO 设置WebView的客户端属性



mWv.evaluateJavascript(); //TODO 可以执行javascript代码，还有回调函数

mWv.loadUrl("javascript:alert('hello')");//也可以执行javascript代码

可以将js代码放到不同的客户端方法中，如可以在加载或者加载完成时调用



32.3.提示框

Toast框位置改变

Toast toast_center = Toast.makeText(getApplicationContext(), "Toast center", Toast.LENGTH_LONG);

toast_center.setGravity(Gravity.CENTER,0,0);

toast_center.show();

自定义Toast（带图片和文字）

先自定义Layout文件，包含了ImageView和TextView

Toast toast_diy = Toast.makeText(getApplicationContext(), "Toast diy", Toast.LENGTH_LONG);

View view = LayoutInflater.from(getApplicationContext()).inflate(R.layout.layout_toast, null);

ImageView imageView = (ImageView) view.findViewById(R.id.toast_iv);

imageView.setImageResource(R.drawable.icon);

TextView textView = (TextView)view.findViewById(R.id.toast_tv);

textView.setText("阿里妈妈");

toast_diy.setView(view);

toast_diy.show();



34.如何使Toast实时显示而不需要等待前一个完成：

方式一：将Toast对象在下一个Toast生效前调用cancel()方法取消掉

方式二：创建一个Toast对象单例的工具类，在单例Toast生效时会将之前的效果中断。

private static Toast mToast;

public static void showMsg(Context context, String msg) {

    if (mToast == null) {

        mToast = Toast.makeText(context, msg, Toast.LENGTH_LONG);

    } else {

        Random random = new Random();

        mToast.setText(msg+random.nextInt());

    }

    mToast.show();

}



35.Dialog选择框

AlertDialog.Builder builder = new AlertDialog.Builder(DialogActivity.this);//用getApplicationContext()会报错

builder.setTitle("请回答:").setMessage("这书好看吗?")

        .setPositiveButton(text,new DialogInterface.OnClickListener(){OnClick(){...}})

可以设置setPositiveButton、setNeuTralButton和setNegativeButton三个按键并设置点击事件。



36.多选框：

builder2.setTitle("掌握的语言:")/*.setMessage("掌握的语言")*/ //TODO 有items就不能设置message

        .setIcon(R.drawable.icon).setItems(array2, new DialogInterface.OnClickListener() {

    @Override

    public void onClick(DialogInterface dialog, int which) {

    }

}).show();

单选框：

将setItems替换为setSingleChoiceItems（array，默认选择下标，listener）

点击弹框外可以取消弹框，需要设置.setCancelable(false)

如果需要点击选项后弹框消失，在onClick中设置dialog.dismiss();

多选框

还需要传入boolean数组来对应选项数组是否被默认选中。用setMultiChoiceItems方法来设置多选框，用setPositiveButton和setNegativeButton来设置按钮。



37.自定义AlertDialog：通过setView方法将自定义的布局设置到弹框中

View view = LayoutInflater.from(getApplicationContext()).inflate(R.layout.layout_dialog_item,null);

final EditText editText1 = (EditText)view.findViewById(R.id.dialog_et_1);

final EditText editText2 = (EditText)view.findViewById(R.id.dialog_et_2);

Button btn_dialog = (Button)view.findViewById(R.id.dialog_btn_1);

btn_dialog.setOnClickListener(new View.OnClickListener() {

    @Override

    public void onClick(View v) {

        ToastUtil.showMsg(getApplication(),editText1.getText().toString() + "	" + editText2.getText().toString());

    }

});

builder5.setTitle("请登录").setView(view).show();



38.ProgressBar设置加载符号或进度

<ProgressBar

    android:id="@+id/pb_3"

    android:layout_width="match_parent"

    android:layout_height="wrap_content"

    android:layout_marginTop="20dp"

    style="@android:style/Widget.ProgressBar.Horizontal"

    android:max="100"

    android:progress="10"

    android:secondaryProgress="30"

    />



通过handler和runnable互调使进度条不断上升，直到边界

Handler handler = new Handler(){

    @Override

    public void handleMessage(@NonNull Message msg) {

        super.handleMessage(msg);

        if(mPb4.getProgress() < 100){

            handler.postDelayed(runnable, 500); //TODO 延迟发送消息给runnable

        }else {

            ToastUtil.showMsg(ProgressBarActivity.this,"Load Complete!"); //TODO 边界

        }

    }

};

Runnable runnable = new Runnable() {

    @Override

    public void run() {

        mPb4.setProgress(mPb4.getProgress() + 5);  //TODO 进度条+5

        handler.sendEmptyMessage(0);    //TODO 发送消息给handler，循环调用直到边界

    }

};



mPb4 = (ProgressBar) findViewById(R.id.pb_4);

mBtn.setOnClickListener(new View.OnClickListener() {

    @Override

    public void onClick(View v) {

        handler.sendEmptyMessage(0);    //TODO 点击之后发送消息执行handle的handlerMessage方法

    }

});



ProgressBar中自定义旋转的图片的设置

<?xml version="1.0" encoding="utf-8"?>

<animated-rotate xmlns:android="http://schemas.android.com/apk/res/android"

    android:drawable="@drawable/touxiang"

    android:pivotX="50%"

    android:pivotY="50%">

</animated-rotate>



在styles.xml文件中 引用自己的旋转图片配置创建自定义的style

<style name="MyProgressBar">

    <item name="android:indeterminateDrawable">@drawable/bg_progress</item>

</style>



<item name="android:indeterminate">true</item> 表示模糊模式，用于旋转的图片；如果为false表示非模糊模式，用于进度条。



39.点击按钮弹出对话

mBtn2.setOnClickListener(new View.OnClickListener() {

    @Override

    public void onClick(View v) {

        ProgressDialog progressDialog = new ProgressDialog(ProgressBarActivity.this);

        progressDialog.setTitle("提示");

        progressDialog.setMessage("正在加载");

        progressDialog.setOnCancelListener(new DialogInterface.OnCancelListener() { //TODO 如果对话被取消则调用该方法

            @Override

            public void onCancel(DialogInterface dialog) {

                ToastUtil.showMsg(getApplicationContext(),"cancal..");

            }

        });

        progressDialog.setCancelable(false); //不能被取消，可以在加载完后调用dismiss方法取消

        progressDialog.show();

    }

});



40.点击按钮弹出对话，加载到100%时自动退出

mBtn3.setOnClickListener(new View.OnClickListener() {

    @Override

    public void onClick(View v) {

        progressDialog = new ProgressDialog(ProgressBarActivity.this);

        progressDialog.setProgressStyle(ProgressDialog.STYLE_HORIZONTAL);

        progressDialog.setTitle("提示");

        progressDialog.setMessage("正在下载...");

        progressDialog.setMax(100);

        progressDialog.setCancelable(false);

        progressDialog.show();

        handler2.sendEmptyMessage(0);

    }

});

Handler handler2 = new Handler(){

    @Override

    public void handleMessage(@NonNull Message msg) {

        super.handleMessage(msg);

        if(progressDialog.getProgress()<100){

            progressDialog.setProgress(progressDialog.getProgress() + 5);

            handler2.postDelayed(runnable2, 200);

        }else{

            ToastUtil.showMsg(getApplicationContext(),"Complete!");

            progressDialog.dismiss();

        }

    }

};

Runnable runnable2 = new Runnable() {

    @Override

    public void run() {

        handler2.sendEmptyMessage(0);

    }

};



ProgressDialog继承自AlertDialog继承自Dialog。

AlertDialog弹框可以设置各种信息；progressBar和ProgressDialog都分为转圈和进度条两种，progressBar在页面上显示，ProgressDialog点击后以对话框形式出现。

ProgressDialog可以在对话框中设置点击按钮，包括BUTTON_POSITIVE，BUTTON_NEUTRAL和BUTTON_POSITIVE

progressDialog.setButton(DialogInterface.BUTTON_POSITIVE, "很好", new DialogInterface.OnClickListener() {

    @Override

    public void onClick(DialogInterface dialog, int which) {

        ToastUtil.showMsg(getApplicationContext(),"good");

    }

});



41.自定义Dialog

创建一个CustomDialog类继承Dialog，创建一个layout文件写成一个登陆页面。在Dialog中关联这个layout，获取其中的标签，设置成为需要的参数。参数和listener可以通过set方法传入。new Dialog对象设置参数和listener，调用show方法来显示自定义layout形式的dialog框。

CustomDialog.IOnCancelListener cancelListener = new CustomDialog.IOnCancelListener() {

    @Override

    public void onCancel(CustomDialog dialog) {

        ToastUtil.showMsg(getApplicationContext(), "取消成功");

        dialog.dismiss();

    }

};

CustomDialog.IOnConfirmListener confirmListener = new CustomDialog.IOnConfirmListener() {

    @Override

    public void onConfirm(CustomDialog dialog) {

        ToastUtil.showMsg(getApplicationContext(), "确认");

        dialog.dismiss();

    }

};

CustomDialog customDialog = new CustomDialog(DialogActivity.this).setTitle("警告").setMsg("确定删除此项").setCancel("取消", cancelListener).setConfirm("确认", confirmListener);

customDialog.show();





public class CustomDialog extends Dialog implements TextView.OnClickListener{

    private TextView mTvTitle,mTvMsg,mTvCancel,mTvConfirm;

    private String title,msg,cancel,confirm;

    private IOnCancelListener cancelListener;

    private IOnConfirmListener confirmListener;

    public CustomDialog(@NonNull Context context) {

        super(context);

    }

    public CustomDialog(@NonNull Context context, int themeResId) {

        super(context, themeResId);

    }

    public CustomDialog setTitle(String title) {

        this.title = title;

        return this;

    }

    public CustomDialog setMsg(String msg) {

        this.msg = msg;

        return this;

    }

    public CustomDialog setCancel(String cancel,IOnCancelListener cancelListener) {

        this.cancel = cancel;

        this.cancelListener = cancelListener;

        return this;

    }

    public CustomDialog setConfirm(String confirm,IOnConfirmListener confirmListener) {

        this.confirm = confirm;

        this.confirmListener = confirmListener;

        return this;

    }

    @Override

    protected void onCreate(@Nullable Bundle savedInstanceState) {

        super.onCreate(savedInstanceState);

        setContentView(R.layout.layout_customdialog);

        mTvTitle = (TextView) findViewById(R.id.custom_tv1);

        mTvMsg = (TextView) findViewById(R.id.custom_tv2);

        mTvCancel = (TextView) findViewById(R.id.custom_tv3);

        mTvConfirm = (TextView) findViewById(R.id.custom_tv4);

        //设置宽度

        WindowManager m = getWindow().getWindowManager();

        Display d = m.getDefaultDisplay();

        WindowManager.LayoutParams p = getWindow().getAttributes();

        Point size = new Point();

        d.getSize(size);

        p.width = (int)(size.x * 0.8); //TODO 设置dialog的宽度为当前手机屏幕宽度的0.8倍

        getWindow().setAttributes(p);

        if(!TextUtils.isEmpty(title)) {

            mTvTitle.setText(title);

        }

        if (!TextUtils.isEmpty(msg)) {

            mTvMsg.setText(msg);

        }

        if (!TextUtils.isEmpty(cancel)){

        mTvCancel.setText(cancel);

        }

        if (!TextUtils.isEmpty(confirm)) {

            mTvConfirm.setText(confirm);

        }

//        mTvCancel.setOnClickListener(this);

//        mTvConfirm.setOnClickListener(this);

        mTvCancel.setOnClickListener(new View.OnClickListener() {

            @Override

            public void onClick(View v) {

                cancelListener.onCancel(CustomDialog.this);

            }

        });

        mTvConfirm.setOnClickListener(new View.OnClickListener() {

            @Override

            public void onClick(View v) {

                confirmListener.onConfirm(CustomDialog.this);

            }

        });

    }

    @Override

    public void onClick(View v) {

        switch (v.getId()){

            case R.id.custom_tv3:

                cancelListener.onCancel(this);

                break;

            case R.id.custom_tv4:

                confirmListener.onConfirm(this);

                break;

        }

    }

    public interface IOnCancelListener{

        void onCancel(CustomDialog dialog);

    }

    public interface IOnConfirmListener{

        void onConfirm(CustomDialog dialog);

    }

}



通过以下方法来设置框的宽度占屏幕的比重：

WindowManager m = getWindow().getWindowManager();

Display d = m.getDefaultDisplay();

WindowManager.LayoutParams p = getWindow().getAttributes();

Point size = new Point();

d.getSize(size);

p.width = (int)(size.x * 0.8); //TODO 设置dialog的宽度为当前手机屏幕宽度的0.8倍

getWindow().setAttributes(p);



圆角矩形边框样式

<?xml version="1.0" encoding="utf-8" ?>

<shape xmlns:android="http://schemas.android.com/apk/res/android"

    android:shape="rectangle">

    <solid android:color="@color/colorWhite"/>

    <corners android:radius="20dp"/>

</shape>



布局很简单，就是正常的界面，用View标签，宽度设置为0.5来做分割线。



因为继承Dialog类有title和背景，所以会有灰色部分。

可以设置styles.xml文件设置去除和透明，通过构造器构造Dialog对象（在layout文件中的设置会被Dialog类覆盖）：

<style name="CustomDialog" parent="android:Theme.Dialog">

    <item name="windowNoTitle">true</item>

    <item name="android:windowIsFloating">true</item>

    <item name="android:windowBackground">@color/colorTransparent</item>

</style>



其他详细设置

</style>

    <style name="dialog_parent" parent="@android:style/Theme.Dialog">

      <!--  设置背景透明-->

        <item name="android:windowBackground">@color/transparent</item>

        <!--设置是否有边框-->

        <item name="android:windowFrame">@null</item>

        <!--设置是否有标题栏-->

        <item name="android:windowNoTitle">true</item>

      <!-- 设置是否有遮盖-->

        <item name="android:windowContentOverlay">@null</item>

      <!-- 设置是否浮在activity之上-->

        <item name="android:windowIsFloating">true</item>

        <!--添加我们的drawable文件-->

        <item name="android:background">@drawable/dialog_background_parent_moving</item>

    </style>



ViewGroup.LayoutParams是什么？？？



42.获取popup框的宽度和高度

mBtn_Popup.getWidth(), ViewGroup.LayoutParams.WRAP_CONTENT



43.PopupWindow

mBtn_Popup = (Button) findViewById(R.id.btn_popup);

        mBtn_Popup.setOnClickListener(new View.OnClickListener() {

            @Override

            public void onClick(View v) {

                View view = getLayoutInflater().inflate(R.layout.layout_popup, null);

                View tv_good = view.findViewById(R.id.tv_good);

                tv_good.setOnClickListener(new View.OnClickListener() { //TODO 设置View中的TextView的点击事件

                    @Override

                    public void onClick(View v) {

                        mPop.dismiss();

                        ToastUtil.showMsg(getApplicationContext(),"good");

                    }

                });

                mPop = new PopupWindow(view,mBtn_Popup.getWidth(), ViewGroup.LayoutParams.WRAP_CONTENT);

                mPop.setBackgroundDrawable(new BitmapDrawable());//TODO 以下设置生效的前提

                mPop.setOutsideTouchable(true); //TODO 窗口会响应窗口外的点击事件（会取消窗口）

                mPop.setFocusable(true);    //TODO 点击按钮时不会再次生效，焦点完全在pop框中

//                mPop.setAnimationStyle(); //设置动画效果

                mPop.showAsDropDown(mBtn_Popup);//TODO 以锚点为相对位置确定弹框的位置

//                mPop.showAtLocation(view, Gravity.CENTER,100,300);//TODO 在父页面中的位置

            }

        });



44.通过在AndroidManifest中设置android:label="Test"

android:theme="@style/Theme.AppCompat.Light.NoActionBar"，来设置是否有标题栏和名字。android:screenOrientation="landscape/portrait"设置横竖屏

android:launchMode设置启动模式；<intent-filter>标签用于设置启动默认启动activity；



45.activity的生命周期：onCreate、onStart、onResume、onPause、onStop和onDestroy。onCreate中绑定页面，onResume中可以设置数据刷新，onPause设置页面暂停，onDestroy用于销毁资源。



46.显示跳转：

//TODO 显示跳转方式一：

//                Intent intent = new Intent(getApplicationContext(),BActivity.class);

//                startActivity(intent);

                //TODO 显示跳转方式二：

//                Intent intent = new Intent();

//                intent.setClass(getApplicationContext(), BActivity.class);

//                startActivity(intent);

                //TODO 显示跳转方式三：

//                Intent intent = new Intent();

//                intent.setClassName(getApplicationContext(), "com.example.myapplication.jump.BActivity");

//                startActivity(intent);

                //TODO 显示跳转方式四：

//                Intent intent = new Intent();

//                intent.setComponent(new ComponentName(getApplicationContext(), "com.example.myapplication.jump.BActivity"));

//                startActivity(intent);

隐式跳转：

需要在AndroidManifest中设置

<action android:name="com.example.myapplication.BActivity" />//起别名（随意取名），下面的名字要和这个对应

<category android:name="android.intent.category.DEFAULT" />

//TODO 隐式调用

Intent intent = new Intent();

intent.setAction("com.example.myapplication.BActivity");

startActivity(intent);





intent.setAction()可以设置调用电话、发邮件、摄像头等。



47.Activity之间的数据传递：

可以在前一个页面通过

Bundle bundle = new Bundle();

bundle.putString("name","记账");

intent.putExtras(bundle); //直接传入bundle

intent.putExtra("version", 1); //通过方法传入bundle，内部也是创建bundle

startActivity(intent);

将信息存入intent中，并在下一页面获取intent信息：

Bundle extras = getIntent().getExtras();

String name = extras.getString("name");

int version = extras.getInt("version");



48.startActivityForResult：

通过startActivityForResult(intent,0)方法跳转页面，可以带一个标志符，表示是哪个方法进行跳转的。跳转的页面通过

Intent intent = new Intent();

Bundle bundle = new Bundle();

bundle.putString("title","I am back!!!");

intent.putExtras(bundle);

setResult(Activity.RESULT_OK,intent);

finish();

intent携带返回的信息，并将自己关闭。

原页面通过方法

@Override

protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {

    super.onActivityResult(requestCode, resultCode, data);

    ToastUtil.showMsg(getApplicationContext(),data.getExtras().getString("title") + "-" + requestCode + "-" + resultCode);

}

获取返回的信息



49.Activity的4种启动模式：

在Android：Manifest中设置android：launchMode属性

standard：标准模式，默认

singleTop：Task栈顶复用

singleTask：在同一个任务栈中存在，则会复用，并且该activity上面的activity会被弹栈

singleInstance：全局中存在同一个activity则会被复用。用于支付界面等。

this.getTaskId()方法获取当前的任务栈号

this.hashCode()方法获取当前对象的哈希值

ActivityInfo activityInfo = getPackageManager().getActivityInfo(getComponentName(), PackageManager.GET_META_DATA);

Log.d("AActivity", activityInfo.taskAffinity);获取当前对象的任务栈名（默认包名，通过该对象跳转的activity都在此栈中），可以通过android:taskAffinity=“...”来启动新任务栈。

当复用activity对象时会调用onNewIntent方法；新建activity对象时会调用onCreate方法。



50.Fragment：

Fragment有自己的声明周期且依赖于Activity。通过getActivity获取Activity，通过FragmentManager的findFragmentById()或findFragmentByTag()获取Fragment。

Fragment和Activity是多对多的关系。

①编写一个layout文件，文件中包括Button和FrameLayout两标签，新建一个ContainerActivity类继承AppCompatActivity类绑定该layout文件。

<FrameLayout

    android:id="@+id/fl_container"

    android:layout_width="match_parent"

    android:layout_height="match_parent"

    android:layout_below="@id/btn_change"

    />

②编写两个类继承Fragment，在类中有两个方法，方法onCreateView中绑定layout，另一个方法onViewCreated在页面创建后生效。编写两个包含TextView标签的layout文件分别绑定两个类。

③ContainerActivity类中的FrameLayout用于放置Fragment类，Button用于切换FrameLayout中的Fragment类。

// 实例化AFragment

AFragment aFragment = new AFragment();

//把AFragment添加到Activity中,记得调用commit

getSupportFragmentManager().beginTransaction().add(R.id.fl_container, aFragment).commitAllowingStateLoss();//避免状态丢失报错崩溃

}

通过给Button设置点击事件，点击事件中设置

if (bFragment == null) {

    bFragment = new BFragment();

}

getSupportFragmentManager().beginTransaction().replace(R.id.fl_container, bFragment).commitAllowingStateLoss();

替换原有的Fragment，达到不刷新页面替换页面中的内容的效果。



51.Fragment传入参数：

Fragment类中有onAttach方法和onDetach方法，用于创建时绑定activity和脱离activity；在onDestroy中设置fragment销毁时取消异步操作任务，否则会有空指针异常。

可以通过新建构造方法传入参数，也可以通过静态工厂方法获取绑定参数的Fragment对象，这样重构该fragment时参数不会消失：

public static AFragment newInstant(String title){

    AFragment fragment = new AFragment();

    Bundle bundle = new Bundle();

    bundle.putString("title",title);

    fragment.setArguments(bundle);  //TODO 重新构造该fragment时会通过反射传入bundle

    return fragment;

}

通过getArguments方法获取参数并设置：

if(getArguments() != null){

    mTvTitle.setText(getArguments().getString("title"));

}

在Activity中通过该静态工厂方法获取带参的fragment对象，添加到layout的framelayout标签中：

AFragment aFragment = AFragment.newInstant("静态方法获取对象并传入参数");

getSupportFragmentManager().beginTransaction().add(R.id.fl_container, aFragment).commitAllowingStateLoss();



52.Fragment回退栈：

通过在Fragment中设置点击事件，用fragment替换当前的fragment，当返回时直接退出fragment所在的layout页面。需要在每次替换时将fragment放入回收栈当中：

getFragmentManager().beginTransaction().replace(R.id.fl_container,new BFragment()).addToBackStack(null).commitAllowingStateLoss();

通过addToBackStace()方法回收被replace()的fragment，在回退时取出。虽然对象是同一个，但是取出fragment时会调用onViewCreated方法重新创建视图view，而不会保留跳转前的view。

如果需要保存fragment的视图，就不能用replace()方法，需要通过隐藏该fragment然后add新的fragment的方式来替代replace()方法。

Fragment fragment = getFragmentManager().findFragmentByTag("a");//在Activity中add方法添加fragment时有个tag参数用来标记该fragment，如将tag设为“a”

if (fragment != null) {

getFragmentManager().beginTransaction().hide(AFragment.this).add(R.id.fl_container, bFragment).addToBackStack(null).commitAllowingStateLoss();

} else {

    getFragmentManager().beginTransaction().replace(R.id.fl_container, bFragment).addToBackStack(null).commitAllowingStateLoss();

}



可以在fragment中修改view的属性，修改后就会生效（如通过点击事件修改view的属性）



53.fragment向activity通讯：

可以在activity中添加方法，在fragment通过getActivity()方法获取activity对象调用添加的方法进行传值。

更规范的写法：在fragment类中写一个接口，activity类继承接口，onAttach方法在关联activity时就会调用，可以在该方法中将context强转为接口对象并调用接口方法完成赋值。



54.监听事件处理机制：

设置监听器有三个要素，分别为事件源，事件和事件监听器。如OnTouchListener监听器的onTouch方法中的参数MotionEvent event就是事件。event.getAction()方法获取该事件的动作，动作分为MotionEvent.ACTION_DOWN、MotionEvent.ACTION_UP等。

监听事件实现方法：

内部类实现

匿名内部类

事件源所在类实现（让activity实现OnClickListener接口，将activity对象作为监听器）

通过外部类实现

布局文件中onClick属性（针对点击事件）

通过布局文件中onClick属性实现监听：

在布局文件中添加标签并通过onClick设置方法名

<Button

android:id="@+id/btn_listener"

...

android:onClick="show"

/>

在activity中添加方法

public void show(View v){

switch(v.getId()){

  case R.id.btn_listener:

  Toast......

  break;

}

}

多个事件廷加同种类型监听器，监听器只会执行最后一个监听器（布局文件中的onClick方法默认是最先执行的）。



55.基于回调的事件处理机制：

①创建MyButton类继承AppCompatButton类，在类中可以重写回调方法，包括onTouchEvent（按键触摸时回调)、onKeyDown（键盘按下时回调）。②然后在Activity的布局文件layout中，将该类名作为标签设置按键，在启动程序点击按键时就会触发MyButton的回调方法，类似监听器，但是如果设置了监听器，监听器的回调方法比Button类的回调方法更快。③可以重写Activity类的回调方法，如onTouchEvent方法，在触发Button类的回调方法后也会触发Activity类的回调方法；可以通过在回调方法中返回true，阻止触发后续的回调方法。



56.为自定义类MyButton按键设置监听器（触摸监听器和点击监听器）和回调方法（触摸回调和点击回调）和dispatchTouchEvent方法。分别在方法中打印自己的信息，顺序如下：

D/MyButton: ---dispatchTouchEvent--- //是所有触摸方法的入口

D/Listener: ---onTouch--- //先调用监听器（return false）

D/MyButton: ---onTouchEvent //在回调函数

D/MyButton: ---dispatchTouchEvent--- //ActionUp也会调用该方法

D/Listener: ---onClick //只调用监听器

dispatchTouchEvent方法中调用的次序是OnTouchListener的回调方法，OnTouchEvent的回调方法；

onTouchEvent方法中调用onClick/onLongClick方法，在ActionDown触发时发送一个100ms延时的runnable信息，检测此时动作，若还是ActionDown且ActionMove没有离开控件，则判定为onClick事件；如果还是ActionDown，则会发送400ms的延时信息判断状态，如果此时还是ActionDown且ActionMove没有离开控件，则判断为onLongClick事件。



57.Handler类作用：

一：未来做某事

mHandler = new Handler();

mHandler.postDelayed(new Runnable() {

    @Override

    public void run() {

        Intent intent = new Intent(getApplicationContext(), MainActivity.class);

        startActivity(intent);

    }

}, 3000);

设置延迟事件，事件触发后在3秒后跳转到主页面。

二：线程间通讯

创建Handler并

mHandler = new Handler(){

    @Override

    public void handleMessage(Message msg){

        super.handleMessage(msg);

        switch (msg.what) {

            case 1:

                ToastUtil.showMsg(getApplication(),"通讯成功");

                break;

        }

    }

};

//开启新线程，并向Handler传递Message

new Thread(){

    @Override

    public void run() {

        Message message = new Message();

        message.what = 1;

        mHandler.sendMessageDelay(message,2000);

    }

}.start();

在mHandler接收到Message后会回调handleMessage方法。



58.数据存储：

SharedPreferences轻量数据存储（是否是第一次打开、用户名密码、设置自动登录等）

xml文件，以K-V形式存储在data/data/{applicationName}/shared_prefs文件夹中。

①在布局文件中设置：

EditText：用于输入

Button：点击保存输入的内容

Button：点击读取保存的内容

TextView：显示保存的内容

②在Activity类中首先获取SharePreferences对象和Editor对象：

sharedPreferences = getSharedPreferences("date", MODE_PRIVATE); //TODO PRIVATE表示只在该app使用（其他设置因为安全性问题已废弃），APPEND表示如果存在同名文件则追加内容

mEditor = sharedPreferences.edit();

③设置点击保存和点击读取的事件：

mBtn_save.setOnClickListener(new View.OnClickListener() {

    @Override

    public void onClick(View v) {

        mEditor.putString("name", mEt_enter.getText().toString());

        mEditor.apply();    //TODO apply()方法异步存储到磁盘，commit()方法同步存储到磁盘

    }

});

mBtn_load.setOnClickListener(new View.OnClickListener() {

    @Override

    public void onClick(View v) {

        String name = sharedPreferences.getString("name","");

        mTv_show.setText(name);

    }

});

点击保存按钮将内容保存到本地，点击读取将本地内容读取出来并显示。



59.applicationId不是包名（创建项目时默认applicationId就是包名），而是应用的ID；相同ID的应用只能下载一个，可以通过修改applicationId来下载多个相同的应用。

date.xml文件内容如下：

<?xml version="1.0" encoding="UTF-8" standalone='yes' ?>

<map>

  <string name="name"></string>

  ......

</map>



60.内部存储（Internal Storage）

/data/data/<applicationId>/shared_prefs

/data/data/<applicationId>/databases //操作SQLite数据库

/data/data/<applicationId>/files

/data/data/<applicationId>/cache

分别通过方法如下方法获得：

getSharedPreferences()

context.getCacheDir()

context.getFilesDir()



61.外部存储：

公有目录(应用卸载不删除)：Environment.getExternalStoragePublicDirectory(int type)

私有目录(随应用卸载而删除)：

/mnt/sdcard/Android/data/data/<applicationId>/cache

/mnt/sdcard/Android/data/data/<applicationId>/files



62.File内部存储：

通过openFileInput方法和openFileOutput方法获取输入和输出流，通过流完成文件的内部存储和读取。

public void save(String content){

    FileOutputStream fos = null;

    try {

        fos = openFileOutput(FILENAME, MODE_PRIVATE);

        fos.write(content.getBytes());

    } catch (IOException e) {

        e.printStackTrace();

    }finally {

        if (fos != null) {

            try {

                fos.close();

            } catch (IOException e) {

                e.printStackTrace();

            }

        }

    }

}

public String load(String file){

    FileInputStream fis = null;

    try {

        fis = openFileInput(file);

        byte[] buff = new byte[1024];

        int length = 0;

        StringBuffer sb = new StringBuffer();

        while((length = fis.read(buff)) > 0){

            sb.append(new String(buff, 0, length, Charset.forName("utf-8")));

        }

        return sb.toString();

    } catch (IOException e) {

        e.printStackTrace();

    }finally{

        if(fis != null){

            try {

                fis.close();

            } catch (IOException e) {

                e.printStackTrace();

            }

        }

    }

    return null;

}



63.File的外部存储：

原理和内部存储一样，不通过openFileInput/openFileOutput方法而是创建FileOutputStream流来存储到指定路径上。

public void savePath(String content,String path,String filename){

    FileOutputStream fos = null;

    try {

        File dir = new File(Environment.getExternalStorageDirectory(),path);

        if (!dir.exists()) {

            dir.mkdirs();

        }

        Log.d("path", dir.getPath());

        File file = new File(dir, filename);

        if (!file.exists()) {

            file.createNewFile();

        }

        fos = new FileOutputStream(file);

        fos.write(content.getBytes());

    }catch(IOException e){

        e.printStackTrace();

    }finally {

        if(fos != null) {

            try {

                fos.close();

            } catch (IOException e) {

                e.printStackTrace();

            }

        }

    }

}

public String loadPath(String path,String filename) {

    FileInputStream fis = null;

    try {

        File file = new File(Environment.getExternalStorageDirectory()+File.separator+path,filename);

        fis = new FileInputStream(file);

        byte[] buff = new byte[1024];

        StringBuffer sb = new StringBuffer();

        int len = 0;

        while ((len = fis.read(buff)) > 0) {

            sb.append(new String(buff, 0, len, Charset.forName("utf-8")));

        }

        return sb.toString();

    } catch (IOException e) {

        e.printStackTrace();

    }finally{

        if (fis != null) {

            try {

                fis.close();

            } catch (IOException e) {

                e.printStackTrace();

            }

        }

    }

    return null;

}

需要注意的是创建文件夹需要在AndroidManifest中设置外部存储权限

<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>

可能还需要在MainActivity中动态获取权限

ActivityCompat.requestPermissions(this,new String[]{Manifest.permission.WRITE_EXTERNAL_STORAGE},1); //TODO 动态获取外部存储的写权限，数组中是需要的权限，响应参数会标志方法的调用



64.动态获取权限会进行弹框显示，需要用户点击授权后才能操作；这里就需要考虑用户不授权或已经授权不需要弹框的情况。



65.broadcast广播：

在发送广播的类中：

Intent intent = new Intent("CJ");

LocalBroadcastManager.getInstance(getApplicationContext()).sendBroadcast(intent);

获取该上下文对应的广播管理器实例，发送广播，内容为String action。

在接收广播的类中，需要注册广播接收器：

LocalBroadcastManager.getInstance(getApplicationContext()).registerReceiver(myBroadcast,filter);

需要传入两个参数，

一个是广播接收器对象：

private class MyBroadcast extends BroadcastReceiver{

        @Override

        public void onReceive(Context context, Intent intent) {

            switch (intent.getAction()){

                case "CJ":

                    mTv_show.setText("收到广播");

//                    Message msg = new Message();

//                    msg.what = 1;

//                    mHandler.sendMessage(msg);

                    Log.d("进入方法",mTv_show.getText().toString());

                    break;

            }

        }

    }

创建类继承BroadcastReceiver，重写onReceive方法（接收广播后的处理逻辑），每次发送都广播都会回调该方法。

另一个是过滤器，对需要监听的action进行筛选：

IntentFilter filter = new IntentFilter();

filter.addAction("CJ"); //只接收action为“CJ”的广播

最后需要在onDestroy方法中注销掉监听器：

@Override

protected void onDestroy() {

    super.onDestroy();

  LocalBroadcastManager.getInstance(getApplication()).unregisterReceiver(myBroadcast);

}



66.属性动画和补间动画：属性动画是实际位置发生改变；补间动画实际位置不变，只是障眼法。

常用的类：

ValueAnimator

ObjectAnimator.ofFloat()

设置旋转动画：

mTv_rotation.animate().rotationYBy(540).setDuration(2000).start();

设置平移动画：

mTv_translation.animate().translationYBy(500).setDuration(2000).start();

//translationY是移动到固定位置，translationYBy是移动设定距离。

设置缩放动画：

mTv_translation.animate().scaleXBy(-1).scaleYBy(-1).setDuration(2000).start();//参数为-1和-1，动画为缩小为点；参数为-2，-2，动画为对称翻转。

设置透明度动画：

mBtn_alpha.animate().alpha(0).setDuration(2000).start();//TODO 透明度，0表示全透明。



67.监听器和复杂动画：

为valueAnimator设置监听器，监听value的变化情况：

ValueAnimator valueAnimator = new ValueAnimator().ofInt(0, 100);

valueAnimator.setDuration(2000);

valueAnimator.addUpdateListener(this);

valueAnimator.start();

@Override

public void onAnimationUpdate(ValueAnimator animation) {

    //TODO 实际值，与设定有关

    Log.d("abc", animation.getAnimatedValue() + "");

    //TODO 进度值0-1

    Log.d("abc", animation.getAnimatedFraction() + "");

}

复杂的动画可以通过ObjectAnimator实现：

ObjectAnimator objectAnimator = ObjectAnimator.ofFloat(mBtn_objAnim_rotation, "rotationY", 0, 360, 180);//从0度旋转到360度，再从360度旋转到180度

objectAnimator.setDuration(2000);

objectAnimator.addUpdateListener(this);

objectAnimator.start();
