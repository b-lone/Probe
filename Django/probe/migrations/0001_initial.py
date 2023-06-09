# Generated by Django 4.2.3 on 2023-07-07 08:07

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    initial = True

    dependencies = [
    ]

    operations = [
        migrations.CreateModel(
            name='Task',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('sum', models.IntegerField()),
            ],
        ),
        migrations.CreateModel(
            name='Template',
            fields=[
                ('id', models.IntegerField(primary_key=True, serialize=False)),
                ('name', models.CharField(max_length=255)),
                ('sdkTag', models.BooleanField()),
                ('usageCount', models.IntegerField()),
                ('clipCount', models.IntegerField()),
                ('canReplaceClipCount', models.IntegerField()),
                ('previewUrl', models.TextField()),
                ('coverUrl', models.TextField()),
                ('downloadUrl', models.TextField()),
                ('last_modified', models.DateTimeField(auto_now=True)),
            ],
        ),
        migrations.CreateModel(
            name='TemplateTestCase',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('position', models.IntegerField()),
                ('template', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='probe.template')),
            ],
            options={
                'ordering': ['position'],
            },
        ),
        migrations.CreateModel(
            name='TestCase',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(max_length=255)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('last_modified', models.DateTimeField(auto_now=True)),
                ('templates', models.ManyToManyField(related_name='test_cases', through='probe.TemplateTestCase', to='probe.template')),
            ],
        ),
        migrations.AddField(
            model_name='templatetestcase',
            name='test_case',
            field=models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='probe.testcase'),
        ),
        migrations.CreateModel(
            name='Result',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('state', models.IntegerField()),
                ('use_montage', models.BooleanField()),
                ('montage_ability', models.BooleanField()),
                ('montage_ability_flag', models.TextField()),
                ('start_memory', models.IntegerField()),
                ('end_memory', models.IntegerField()),
                ('max_memory', models.IntegerField()),
                ('duration', models.IntegerField()),
                ('error_msg', models.TextField()),
                ('file_path', models.TextField()),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('last_modified', models.DateTimeField(auto_now=True)),
                ('result', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='probe.task')),
                ('template', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='probe.template')),
            ],
        ),
        migrations.CreateModel(
            name='FrameRenderingTime',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('position', models.BigIntegerField()),
                ('rendering_time', models.BigIntegerField()),
                ('result', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='probe.result')),
            ],
            options={
                'ordering': ['position'],
            },
        ),
    ]
