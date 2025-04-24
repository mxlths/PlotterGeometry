from setuptools import setup, find_packages

setup(
    name="geometron",
    version="0.1.0",
    packages=find_packages(),
    install_requires=[
        "numpy",
        "scipy",
        "PyQt6",
        "pyqtgraph",
        "vispy",
        "svgwrite",
        "lxml",
        "attrs"
    ],
    entry_points={
        'console_scripts': [
            'geometron=geometron.main:main',
        ],
    },
    python_requires=">=3.8",
    author="Your Name",
    author_email="your.email@example.com",
    description="A multi-layer algorithmic geometry generator for pen plotting.",
    long_description=open('README.md').read(),
    long_description_content_type='text/markdown',
    url="https://github.com/yourusername/geometron",
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
) 