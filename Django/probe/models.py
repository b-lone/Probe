from django.db import models

class TestCase(models.Model):
    name = models.CharField(max_length=255)
    created_at = models.DateTimeField(auto_now_add=True)
    last_modified = models.DateTimeField(auto_now=True)

    templates = models.ManyToManyField('Template', through='TemplateTestCase', related_name='test_cases')

class Template(models.Model):
    id = models.IntegerField(primary_key=True)
    name = models.CharField(max_length=255)
    sdkTag = models.BooleanField(default=False)
    usageCount = models.IntegerField(default=0)
    clipCount = models.IntegerField(default=0)
    canReplaceClipCount = models.IntegerField(default=0)
    previewUrl = models.TextField()
    coverUrl = models.TextField()
    downloadUrl = models.TextField()
    last_modified = models.DateTimeField(auto_now=True)

class TemplateTestCase(models.Model):
    template = models.ForeignKey(Template, on_delete=models.CASCADE)
    test_case = models.ForeignKey(TestCase, on_delete=models.CASCADE)
    position = models.IntegerField(default=0)

    class Meta:
        ordering = ['position']

class Task(models.Model):
    sum = models.IntegerField(default=0)

class Result(models.Model):
    state = models.IntegerField(default=0)
    use_montage = models.BooleanField(default=False)
    montage_ability = models.BooleanField(default=False)
    montage_ability_flag = models.TextField()
    start_memory = models.IntegerField(default=0)
    end_memory = models.IntegerField(default=0)
    max_memory = models.IntegerField(default=0)
    duration = models.IntegerField(default=0)
    error_msg = models.TextField()
    file_path = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    last_modified = models.DateTimeField(auto_now=True)

    task = models.ForeignKey(Task, on_delete=models.CASCADE)
    template = models.ForeignKey(Template, on_delete=models.CASCADE)

class FrameRenderingTime(models.Model):
    position = models.BigIntegerField(default=0)
    rendering_time = models.BigIntegerField(default=0)

    result = models.ForeignKey(Result, on_delete=models.CASCADE)

    class Meta:
        ordering = ['position']