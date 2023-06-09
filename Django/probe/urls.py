"""
URL configuration for probe project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/4.2/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path
from . import views
from . import testcase_handler
from . import template_handler
from . import task_handler
from . import result_handler
from . import frame_rendering_time_handler

urlpatterns = [
    path('admin/', admin.site.urls),
    path('testcase/', testcase_handler.testcase, name='testcase'),
    path('testcases/', testcase_handler.testcases, name='testcases'),
    path('template/', template_handler.template, name='template'),
    path('templates/', template_handler.templates, name='templates'),
    path('task/', task_handler.task, name='task'),
    path('tasks/', task_handler.tasks, name='tasks'),
    path('result/', result_handler.result, name='result'),
    path('results/', result_handler.results, name='results'),
    path('frt/', frame_rendering_time_handler.frame_rendering_time, name='frt'),
    path('frts/', frame_rendering_time_handler.frame_rendering_times, name='frts'),
]
